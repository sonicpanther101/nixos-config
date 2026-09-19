/*
 * wl-monitor-invert
 *
 * Wayland-native, per-monitor equivalent of `xcalib -i -a`.
 *
 * xcalib relies on X11's XF86VidModeGamma extension, which does not exist
 * on Wayland. The wlroots analogue is wlr-gamma-control-unstable-v1, which
 * lets a client push a gamma ramp to ONE specific output. Hyprland's
 * built-in `decoration:screen_shader` cannot do this: it is compositor-wide
 * and always applies to every monitor at once. This tool talks to the
 * gamma-control protocol directly so only the requested output is affected.
 *
 * Usage:
 *   wl-monitor-invert <output-name>     e.g. wl-monitor-invert DP-1
 *   wl-monitor-invert --list            list every output name seen
 *
 * The program blocks, holding exclusive gamma control of that output for
 * as long as it runs. Killing it (SIGTERM/SIGINT, e.g. via `pkill -f`)
 * closes the Wayland connection, which makes the compositor restore the
 * output's original gamma table automatically -- no cleanup code needed.
 *
 * Note: only one client may hold gamma control of an output at a time, so
 * this will not coexist with hyprsunset/wlsunset/gammastep running on the
 * same monitor.
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <wayland-client.h>

#include "wlr-gamma-control-unstable-v1-client-protocol.h"

#define MAX_OUTPUTS 16

struct output_entry {
    struct wl_output *output;
    uint32_t name_id; /* registry global name (numeric id) */
    char *name;       /* human name, e.g. "DP-1" (from wl_output.name) */
};

static struct output_entry outputs[MAX_OUTPUTS];
static int output_count = 0;

static struct zwlr_gamma_control_manager_v1 *gamma_manager = NULL;
static struct zwlr_gamma_control_v1 *gamma_control = NULL;
static int gamma_done = 0;
static int gamma_failed_flag = 0;

/* ---- wl_output listener: only care about the "name" event ---- */

static void output_handle_geometry(void *data, struct wl_output *wl_output,
        int32_t x, int32_t y, int32_t pw, int32_t ph, int32_t subpixel,
        const char *make, const char *model, int32_t transform) {
    (void)data; (void)wl_output; (void)x; (void)y; (void)pw; (void)ph;
    (void)subpixel; (void)make; (void)model; (void)transform;
}

static void output_handle_mode(void *data, struct wl_output *wl_output,
        uint32_t flags, int32_t w, int32_t h, int32_t refresh) {
    (void)data; (void)wl_output; (void)flags; (void)w; (void)h; (void)refresh;
}

static void output_handle_done(void *data, struct wl_output *wl_output) {
    (void)data; (void)wl_output;
}

static void output_handle_scale(void *data, struct wl_output *wl_output,
        int32_t factor) {
    (void)data; (void)wl_output; (void)factor;
}

static void output_handle_name(void *data, struct wl_output *wl_output,
        const char *name) {
    (void)wl_output;
    struct output_entry *entry = data;
    free(entry->name);
    entry->name = strdup(name);
}

static void output_handle_description(void *data, struct wl_output *wl_output,
        const char *description) {
    (void)data; (void)wl_output; (void)description;
}

static const struct wl_output_listener output_listener = {
    .geometry = output_handle_geometry,
    .mode = output_handle_mode,
    .done = output_handle_done,
    .scale = output_handle_scale,
    .name = output_handle_name,
    .description = output_handle_description,
};

/* ---- zwlr_gamma_control_v1 listener ---- */

static uint32_t gamma_size = 0;

static void gamma_control_handle_gamma_size(void *data,
        struct zwlr_gamma_control_v1 *control, uint32_t size) {
    (void)data; (void)control;
    gamma_size = size;
    gamma_done = 1;
}

static void gamma_control_handle_failed(void *data,
        struct zwlr_gamma_control_v1 *control) {
    (void)data; (void)control;
    gamma_failed_flag = 1;
    gamma_done = 1;
}

static const struct zwlr_gamma_control_v1_listener gamma_control_listener = {
    .gamma_size = gamma_control_handle_gamma_size,
    .failed = gamma_control_handle_failed,
};

/* ---- registry listener ---- */

static void registry_handle_global(void *data, struct wl_registry *registry,
        uint32_t name, const char *interface, uint32_t version) {
    (void)data;
    if (strcmp(interface, wl_output_interface.name) == 0) {
        if (output_count >= MAX_OUTPUTS) return;
        uint32_t bind_version = version < 4 ? version : 4;
        struct wl_output *output = wl_registry_bind(registry, name,
                &wl_output_interface, bind_version);
        struct output_entry *entry = &outputs[output_count++];
        entry->output = output;
        entry->name_id = name;
        entry->name = NULL;
        wl_output_add_listener(output, &output_listener, entry);
    } else if (strcmp(interface, zwlr_gamma_control_manager_v1_interface.name) == 0) {
        gamma_manager = wl_registry_bind(registry, name,
                &zwlr_gamma_control_manager_v1_interface, 1);
    }
}

static void registry_handle_global_remove(void *data,
        struct wl_registry *registry, uint32_t name) {
    (void)data; (void)registry; (void)name;
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_handle_global,
    .global_remove = registry_handle_global_remove,
};

static int write_ramp_fd(uint32_t size) {
    int fd = memfd_create("wl-monitor-invert-ramp", 0);
    if (fd < 0) {
        perror("memfd_create");
        return -1;
    }
    size_t total = (size_t)size * 3 * sizeof(uint16_t);
    if (ftruncate(fd, (off_t)total) < 0) {
        perror("ftruncate");
        close(fd);
        return -1;
    }
    uint16_t *map = mmap(NULL, total, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (map == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return -1;
    }

    /* Inverted ramp: input i maps to (max - i) instead of i, for each of
     * the three channels (they are stored back-to-back: all R, then all
     * G, then all B). This flips every colour the same way `xcalib -i`
     * does on X11. */
    for (uint32_t ch = 0; ch < 3; ch++) {
        uint16_t *ramp = map + ch * size;
        for (uint32_t i = 0; i < size; i++) {
            uint32_t inverted = size > 1 ? (size - 1 - i) : 0;
            ramp[i] = (uint16_t)((inverted * 65535U) / (size > 1 ? (size - 1) : 1));
        }
    }

    munmap(map, total);
    lseek(fd, 0, SEEK_SET);
    return fd;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <output-name>\n"
                        "       %s --list\n", argv[0], argv[0]);
        return 2;
    }
    const char *want = argv[1];
    int list_only = strcmp(want, "--list") == 0;

    struct wl_display *display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "wl-monitor-invert: failed to connect to a Wayland compositor "
                        "(is WAYLAND_DISPLAY set?)\n");
        return 1;
    }

    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);

    /* First roundtrip: receive the global adverts and issue our binds. */
    wl_display_roundtrip(display);
    /* Second roundtrip: receive the wl_output info events (name, etc.)
     * that the compositor sends right after we bind each output. */
    wl_display_roundtrip(display);

    if (list_only) {
        for (int i = 0; i < output_count; i++) {
            printf("%s\n", outputs[i].name ? outputs[i].name : "(unnamed)");
        }
        wl_display_disconnect(display);
        return 0;
    }

    if (!gamma_manager) {
        fprintf(stderr, "wl-monitor-invert: compositor does not support "
                        "wlr-gamma-control-unstable-v1\n");
        return 1;
    }

    struct wl_output *target = NULL;
    for (int i = 0; i < output_count; i++) {
        if (outputs[i].name && strcmp(outputs[i].name, want) == 0) {
            target = outputs[i].output;
            break;
        }
    }
    if (!target) {
        fprintf(stderr, "wl-monitor-invert: no output named '%s'. Known outputs:\n", want);
        for (int i = 0; i < output_count; i++) {
            fprintf(stderr, "  %s\n", outputs[i].name ? outputs[i].name : "(unnamed)");
        }
        return 1;
    }

    gamma_control = zwlr_gamma_control_manager_v1_get_gamma_control(gamma_manager, target);
    zwlr_gamma_control_v1_add_listener(gamma_control, &gamma_control_listener, NULL);

    while (!gamma_done) {
        if (wl_display_dispatch(display) < 0) {
            fprintf(stderr, "wl-monitor-invert: connection error while waiting for gamma_size\n");
            return 1;
        }
    }
    if (gamma_failed_flag || gamma_size == 0) {
        fprintf(stderr, "wl-monitor-invert: '%s' does not support gamma control "
                        "(already in use by another tool, e.g. hyprsunset/wlsunset?)\n", want);
        return 1;
    }

    int fd = write_ramp_fd(gamma_size);
    if (fd < 0) return 1;
    zwlr_gamma_control_v1_set_gamma(gamma_control, fd);
    close(fd);
    wl_display_flush(display);

    /* Hold the connection open -- this is what keeps the inverted ramp
     * active. Killing this process closes the socket and the compositor
     * restores the monitor's normal gamma table for us. */
    while (wl_display_dispatch(display) >= 0) {
        /* keep going */
    }

    return 0;
}
