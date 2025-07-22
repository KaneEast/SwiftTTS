import Foundation

public enum TTSEvent {
    case started(sentence: String)
    case paused
    case resumed
    case stopped
    case completed(sentence: String)
    case error(Error)
    case queueCompleted
    case progressChanged(progress: Float)
}
