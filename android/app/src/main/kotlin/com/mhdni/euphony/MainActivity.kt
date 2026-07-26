package com.mhdni.euphony

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity, not FlutterActivity: audio_service routes media button
// intents and service reconnection through it. With a plain FlutterActivity the
// notification and lock-screen controls never reach the app.
class MainActivity : AudioServiceActivity()
