import { studyMode, studyPaused, timeLeftStudying, studying } from "./study"

export default function StartButton() {
    return <button
        className="StartButton"
        onClicked={() => {
            studyMode.set(!studyMode.get())
            if (studyMode.get()) {
                studyPaused.set(false)
                timeLeftStudying.set(31)
                studying.set(true)
            }
        }}>
        <label label="" />
    </button>
}