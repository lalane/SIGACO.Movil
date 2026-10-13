package com.idare.sigaco_movil

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    // Se conserva para que el canal viva tanto como la actividad.
    private var pdf: PdfChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pdf = PdfChannel(flutterEngine.dartExecutor.binaryMessenger)
    }
}
