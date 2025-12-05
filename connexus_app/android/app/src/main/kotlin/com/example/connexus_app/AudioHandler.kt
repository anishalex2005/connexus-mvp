package com.example.connexus_app

import android.content.Context
import android.media.AudioManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AudioHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    private val audioManager: AudioManager by lazy {
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setAudioMode" -> {
                val mode = call.argument<String>("mode")
                setAudioMode(mode, result)
            }

            "setSpeaker" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setSpeaker(enabled, result)
            }

            "setMute" -> {
                val muted = call.argument<Boolean>("muted") ?: false
                setMute(muted, result)
            }

            else -> result.notImplemented()
        }
    }

    private fun setAudioMode(mode: String?, result: MethodChannel.Result) {
        try {
            when (mode) {
                "voice_call" -> {
                    audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                    audioManager.isSpeakerphoneOn = false
                }

                "normal" -> {
                    audioManager.mode = AudioManager.MODE_NORMAL
                    audioManager.isSpeakerphoneOn = false
                }
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("AUDIO_ERROR", e.message, null)
        }
    }

    private fun setSpeaker(enabled: Boolean, result: MethodChannel.Result) {
        try {
            audioManager.isSpeakerphoneOn = enabled
            result.success(true)
        } catch (e: Exception) {
            result.error("SPEAKER_ERROR", e.message, null)
        }
    }

    private fun setMute(muted: Boolean, result: MethodChannel.Result) {
        try {
            audioManager.isMicrophoneMute = muted
            result.success(true)
        } catch (e: Exception) {
            result.error("MUTE_ERROR", e.message, null)
        }
    }
}


