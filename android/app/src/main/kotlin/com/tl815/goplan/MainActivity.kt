package com.tl815.goplan

import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.amap.api.maps.AMap
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.MapView
import com.amap.api.maps.MapsInitializer
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.LatLngBounds
import com.amap.api.maps.model.MarkerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity : FlutterActivity() {
    private val mapViews = mutableSetOf<NativeMapPlatformView>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MapsInitializer.updatePrivacyShow(this, true, true)
        MapsInitializer.updatePrivacyAgree(this, true)

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory("goplan/native_map_view", NativeMapViewFactory())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "goplan/native_map")
            .setMethodCallHandler { call, result ->
                NativeMapCommandBus.handle(call, result)
            }
    }

    override fun onResume() {
        super.onResume()
        mapViews.forEach { it.onResume() }
    }

    override fun onPause() {
        mapViews.forEach { it.onPause() }
        super.onPause()
    }

    override fun onDestroy() {
        mapViews.toList().forEach { it.dispose() }
        mapViews.clear()
        super.onDestroy()
    }

    private inner class NativeMapViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            @Suppress("UNCHECKED_CAST")
            val params = args as? Map<String, Any?>
            val pois = params?.get("pois") as? List<Map<String, Any?>> ?: emptyList()
            return NativeMapPlatformView(context, pois).also {
                mapViews.add(it)
                NativeMapCommandBus.attach(it)
            }
        }
    }
}

private object NativeMapCommandBus {
    private var activeView: NativeMapPlatformView? = null

    fun attach(view: NativeMapPlatformView) {
        activeView = view
    }

    fun detach(view: NativeMapPlatformView) {
        if (activeView === view) activeView = null
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setMarkers" -> {
                @Suppress("UNCHECKED_CAST")
                activeView?.setPois(call.arguments as? List<Map<String, Any?>> ?: emptyList())
                result.success(null)
            }
            "moveCamera" -> {
                @Suppress("UNCHECKED_CAST")
                val params = call.arguments as? Map<String, Any?>
                activeView?.moveCamera(params)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}

private class NativeMapPlatformView(
    context: Context,
    pois: List<Map<String, Any?>>
) : PlatformView {
    private val root = FrameLayout(context)
    private var mapView: MapView? = null
    private var map: AMap? = null
    private var fallbackText: TextView? = null

    init {
        if (supportsAmapNativeLibs()) {
            mapView = MapView(context).also { view ->
                view.onCreate(Bundle())
                root.addView(
                    view,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                    )
                )
                map = view.map.apply {
                    uiSettings.isZoomControlsEnabled = false
                    uiSettings.isCompassEnabled = false
                    uiSettings.isMyLocationButtonEnabled = true
                    moveCamera(CameraUpdateFactory.newLatLngZoom(LatLng(41.8, 123.43), 14f))
                }
            }
        } else {
            showUnsupportedAbiFallback(context)
        }
        setPois(pois)
    }

    fun setPois(pois: List<Map<String, Any?>>) {
        val amap = map
        if (amap == null) {
            val names = pois.take(4).joinToString(" / ") { it["name"].toString() }
            fallbackText?.text = if (pois.isEmpty()) {
                "当前 x86_64 模拟器不支持高德原生地图 so\n请用 ARM 安卓真机预览地图"
            } else {
                "当前 x86_64 模拟器不支持高德原生地图 so\n已收到 ${pois.size} 个 POI：$names\n请用 ARM 安卓真机预览真实地图"
            }
            return
        }

        amap.clear()
        val boundsBuilder = LatLngBounds.Builder()
        var hasPoint = false

        pois.forEach { poi ->
            val lat = (poi["latitude"] as? Number)?.toDouble() ?: return@forEach
            val lng = (poi["longitude"] as? Number)?.toDouble() ?: return@forEach
            val name = poi["name"]?.toString().orEmpty()
            val category = poi["category"]?.toString().orEmpty()
            val point = LatLng(lat, lng)

            amap.addMarker(
                MarkerOptions()
                    .position(point)
                    .title(name)
                    .snippet(category)
                    .icon(BitmapDescriptorFactory.defaultMarker(markerHue(category)))
            )

            boundsBuilder.include(point)
            hasPoint = true
        }

        if (hasPoint) {
            amap.animateCamera(CameraUpdateFactory.newLatLngBounds(boundsBuilder.build(), 96))
        }
    }

    fun moveCamera(params: Map<String, Any?>?) {
        val amap = map ?: return
        val lat = (params?.get("latitude") as? Number)?.toDouble() ?: return
        val lng = (params["longitude"] as? Number)?.toDouble() ?: return
        val zoom = (params["zoom"] as? Number)?.toFloat() ?: 14f
        amap.animateCamera(CameraUpdateFactory.newLatLngZoom(LatLng(lat, lng), zoom))
    }

    fun onResume() {
        mapView?.onResume()
    }

    fun onPause() {
        mapView?.onPause()
    }

    override fun getView(): View = root

    override fun dispose() {
        NativeMapCommandBus.detach(this)
        mapView?.onDestroy()
    }

    private fun markerHue(category: String): Float {
        return when (category) {
            "food" -> BitmapDescriptorFactory.HUE_ORANGE
            "hotel" -> BitmapDescriptorFactory.HUE_AZURE
            "shopping" -> BitmapDescriptorFactory.HUE_ROSE
            "transport" -> BitmapDescriptorFactory.HUE_GREEN
            else -> BitmapDescriptorFactory.HUE_CYAN
        }
    }

    private fun supportsAmapNativeLibs(): Boolean {
        return Build.SUPPORTED_ABIS.none { it.contains("x86", ignoreCase = true) }
    }

    private fun showUnsupportedAbiFallback(context: Context) {
        root.setBackgroundColor(Color.rgb(232, 240, 232))
        val title = TextView(context).apply {
            text = "地图预览"
            setTextColor(Color.rgb(28, 28, 30))
            textSize = 18f
            gravity = Gravity.CENTER
        }
        fallbackText = TextView(context).apply {
            setTextColor(Color.rgb(92, 103, 92))
            textSize = 13f
            gravity = Gravity.CENTER
            text = "当前 x86_64 模拟器不支持高德原生地图 so\n请用 ARM 安卓真机预览地图"
        }
        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            addView(title)
            addView(fallbackText)
        }
        root.addView(
            column,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )
    }
}
