package com.idare.sigaco_movil

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Muestra paginas de un PDF con el `PdfRenderer` de Android (sin plugin de
 * terceros). Solo dibuja: el archivo ya esta en la cache de la app y la app lo
 * borra al cerrar la vista previa.
 *
 * `PdfRenderer` no admite hilos ni dos paginas abiertas a la vez: todo pasa por
 * un unico hilo de trabajo.
 */
class PdfChannel(messenger: BinaryMessenger) {
    private class Document(val renderer: PdfRenderer, val descriptor: ParcelFileDescriptor)

    private val documents = HashMap<String, Document>()
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            worker.execute {
                try {
                    val value = handle(call)
                    main.post { result.success(value) }
                } catch (e: Exception) {
                    main.post { result.error("PDF_ERROR", e.message, null) }
                }
            }
        }
    }

    private fun handle(call: MethodCall): Any? {
        val path = call.argument<String>("path") ?: throw IllegalArgumentException("path")
        return when (call.method) {
            "open" -> open(path)
            "render" -> render(
                path,
                call.argument<Int>("page") ?: 0,
                call.argument<Int>("width") ?: 1080,
            )
            "close" -> {
                close(path)
                null
            }
            else -> throw IllegalArgumentException(call.method)
        }
    }

    private fun open(path: String): Map<String, Any> {
        close(path)
        val descriptor = ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)
        try {
            val renderer = PdfRenderer(descriptor)
            val sizes = ArrayList<List<Double>>()
            for (i in 0 until renderer.pageCount) {
                val page = renderer.openPage(i)
                try {
                    sizes.add(listOf(page.width.toDouble(), page.height.toDouble()))
                } finally {
                    page.close()
                }
            }
            documents[path] = Document(renderer, descriptor)
            return mapOf("pages" to sizes)
        } catch (e: Exception) {
            descriptor.close()
            throw e
        }
    }

    private fun render(path: String, index: Int, requestedWidth: Int): ByteArray {
        val document = documents[path] ?: throw IllegalStateException("PDF no abierto")
        val page = document.renderer.openPage(index)
        try {
            val width = max(1, min(requestedWidth, MAX_WIDTH))
            val height = max(1, (width.toFloat() * page.height / page.width).roundToInt())
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            try {
                // El PDF no trae fondo: sin esto el texto negro queda sobre transparente.
                bitmap.eraseColor(Color.WHITE)
                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                val out = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 92, out)
                return out.toByteArray()
            } finally {
                bitmap.recycle()
            }
        } finally {
            page.close()
        }
    }

    private fun close(path: String) {
        val document = documents.remove(path) ?: return
        try {
            document.renderer.close()
        } finally {
            document.descriptor.close()
        }
    }

    companion object {
        const val CHANNEL = "sigaco/pdf"

        /** Una pagina muy grande agotaria la memoria del telefono. */
        private const val MAX_WIDTH = 2400
    }
}
