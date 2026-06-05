package com.ind.classifieds

import android.app.Application
import android.util.Log
import com.facebook.FacebookSdk
import com.facebook.LoggingBehavior
import com.facebook.appevents.AppEventsLogger
import kotlinx.coroutines.*

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        try {
            runBlocking {
                withContext(Dispatchers.Default) {
                    // ✅ Set App ID & Client Token
                    FacebookSdk.setApplicationId("1143991907864941")
                    FacebookSdk.setClientToken("84c9ca7a1eb813593b2558bf28599c8e")

                    // ✅ Enable detailed Facebook App Event logging
                    FacebookSdk.setIsDebugEnabled(true)
                    FacebookSdk.addLoggingBehavior(LoggingBehavior.APP_EVENTS)
                    FacebookSdk.addLoggingBehavior(LoggingBehavior.DEVELOPER_ERRORS)
                    FacebookSdk.addLoggingBehavior(LoggingBehavior.INCLUDE_ACCESS_TOKENS)

                    // ✅ Initialize SDK
                    FacebookSdk.sdkInitialize(applicationContext)
                    FacebookSdk.fullyInitialize()

                    // ✅ Activate App Event tracking
                    AppEventsLogger.activateApp(this@MainApplication)

                    // ✅ Optional: Control flushing behavior
                    AppEventsLogger.setFlushBehavior(AppEventsLogger.FlushBehavior.EXPLICIT_ONLY)
                }
            }
            Log.d("MetaSDK", "✅ Facebook SDK initialized with logging enabled")
        } catch (e: Exception) {
            Log.e("MetaSDK", "❌ Meta SDK init failed: ${e.message}")
        }
    }
}
