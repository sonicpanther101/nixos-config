''
  <?xml version="1.0" encoding="UTF-8"?>
  <interface>
    <requires lib="gtk" version="4.0"></requires>
    <object class="GtkBox" id="ItemBox">
      <style>
        <class name="item-box"></class>
        <class name="wallpaper-item"></class>
      </style>
      <property name="orientation">vertical</property>
      <property name="spacing">4</property>
      <property name="halign">center</property>
      <child>
        <object class="GtkLabel" id="ItemImageFont">
          <style>
            <class name="item-image-text"></class>
          </style>
          <property name="width-chars">0</property>
          <property name="visible">false</property>
        </object>
      </child>
      <child>
        <object class="GtkImage" id="ItemImage">
          <style>
            <class name="item-image"></class>
            <class name="wallpaper-preview"></class>
          </style>
          <property name="icon-size">large</property>
          <property name="hexpand">true</property>
          <property name="vexpand">true</property>
        </object>
      </child>
      <child>
        <object class="GtkBox" id="ItemTextBox">
          <style>
            <class name="item-text-box"></class>
          </style>
          <property name="orientation">vertical</property>
          <property name="hexpand">true</property>
          <property name="spacing">0</property>
          <child>
            <object class="GtkLabel" id="ItemText">
              <style>
                <class name="item-text"></class>
                <class name="wallpaper-label"></class>
              </style>
              <property name="ellipsize">end</property>
              <property name="xalign">0.5</property>
              <property name="halign">center</property>
            </object>
          </child>
          <child>
            <object class="GtkLabel" id="ItemSubtext">
              <style>
                <class name="item-subtext"></class>
              </style>
              <property name="ellipsize">end</property>
              <property name="xalign">0.5</property>
              <property name="halign">center</property>
              <property name="visible">false</property>
            </object>
          </child>
        </object>
      </child>
      <child>
        <object class="GtkLabel" id="QuickActivation">
          <style>
            <class name="item-quick-activation"></class>
          </style>
          <property name="wrap">false</property>
          <property name="valign">center</property>
          <property name="xalign">0</property>
          <property name="yalign">0.5</property>
          <property name="visible">false</property>
        </object>
      </child>
    </object>
  </interface>
''