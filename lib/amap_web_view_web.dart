// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class AmapWebPoi {
  const AmapWebPoi({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String category;
}

class AmapWebView extends StatefulWidget {
  const AmapWebView({super.key, required this.pois});

  final List<AmapWebPoi> pois;

  @override
  State<AmapWebView> createState() => _AmapWebViewState();
}

class _AmapWebViewState extends State<AmapWebView> {
  late final String _viewType =
      'goplan-amap-web-${DateTime.now().microsecondsSinceEpoch}';
  late final html.DivElement _container;
  js.JsObject? _map;
  js.JsObject? _markerLayer;
  bool _registered = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _container = html.DivElement()
      ..id = _viewType
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = '0'
      ..style.margin = '0'
      ..style.padding = '0';
    _registerView();
    unawaited(_loadAndRender());
  }

  @override
  void didUpdateWidget(covariant AmapWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pois != widget.pois && _map != null) {
      _renderPois();
    }
  }

  void _registerView() {
    if (_registered) return;
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _container,
    );
    _registered = true;
  }

  Future<void> _loadAndRender() async {
    try {
      final config = _readConfig();
      if (config.key.isEmpty || config.key == 'YOUR_AMAP_WEB_KEY') {
        setState(() {
          _loading = false;
          _error = '请先在 web/index.html 配置高德 Web JS API Key';
        });
        return;
      }

      await _loadAmapScript(config);
      _createMap();
      _renderPois();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '高德 Web 地图加载失败：$error';
      });
    }
  }

  _AmapWebConfig _readConfig() {
    final raw = js.context['goplanAmapConfig'];
    if (raw is! js.JsObject) return const _AmapWebConfig();
    final key = raw.hasProperty('key') ? raw['key']?.toString() ?? '' : '';
    final securityJsCode = raw.hasProperty('securityJsCode')
        ? raw['securityJsCode']?.toString() ?? ''
        : '';
    final serviceHost = raw.hasProperty('serviceHost')
        ? raw['serviceHost']?.toString() ?? ''
        : '';
    return _AmapWebConfig(
      key: key,
      securityJsCode: securityJsCode,
      serviceHost: serviceHost,
    );
  }

  Future<void> _loadAmapScript(_AmapWebConfig config) {
    if (js.context.hasProperty('AMap')) return Future<void>.value();

    if (config.securityJsCode.isNotEmpty || config.serviceHost.isNotEmpty) {
      final securityConfig = js.JsObject.jsify({
        if (config.securityJsCode.isNotEmpty)
          'securityJsCode': config.securityJsCode,
        if (config.serviceHost.isNotEmpty) 'serviceHost': config.serviceHost,
      });
      js.context['_AMapSecurityConfig'] = securityConfig;
    }

    final completer = Completer<void>();
    final script = html.ScriptElement()
      ..src =
          'https://webapi.amap.com/maps?v=2.0&key=${Uri.encodeComponent(config.key)}'
      ..async = true;

    script.onLoad.first.then((_) => completer.complete());
    script.onError.first.then((_) {
      completer.completeError('无法加载 webapi.amap.com/maps');
    });
    html.document.head!.append(script);
    return completer.future.timeout(const Duration(seconds: 12));
  }

  void _createMap() {
    final amap = js.context['AMap'] as js.JsObject;
    _map = js.JsObject(amap['Map'], [
      _container,
      js.JsObject.jsify({
        'zoom': 13,
        'center': [123.4315, 41.8003],
        'viewMode': '2D',
        'mapStyle': 'amap://styles/normal',
      }),
    ]);
  }

  void _renderPois() {
    final map = _map;
    if (map == null) return;

    if (_markerLayer != null) {
      map.callMethod('remove', [_markerLayer]);
      _markerLayer = null;
    }

    final amap = js.context['AMap'] as js.JsObject;
    final markers = widget.pois.map((poi) {
      final color = _categoryColor(poi.category);
      final content =
          '<div style="display:flex;align-items:center;gap:6px;padding:6px 8px;'
          'background:white;border-radius:999px;box-shadow:0 4px 14px rgba(0,0,0,.16);'
          'font:12px -apple-system,BlinkMacSystemFont,Segoe UI,sans-serif;color:#222;">'
          '<span style="width:10px;height:10px;border-radius:50%;background:$color;display:inline-block;"></span>'
          '<span style="max-width:90px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${_escapeHtml(poi.name)}</span>'
          '</div>';
      return js.JsObject(amap['Marker'], [
        js.JsObject.jsify({
          'position': [poi.longitude, poi.latitude],
          'title': poi.name,
          'content': content,
          'anchor': 'bottom-center',
        }),
      ]);
    }).toList();

    _markerLayer = js.JsObject.jsify(markers);
    map.callMethod('add', [_markerLayer]);

    if (markers.isNotEmpty) {
      map.callMethod('setFitView', [
        _markerLayer,
        false,
        [88, 42, 120, 42],
      ]);
    }
  }

  String _categoryColor(String category) {
    return switch (category) {
      'food' => '#FFA629',
      'hotel' => '#4EA9FF',
      'shopping' => '#FF6BA6',
      'transport' => '#7BC69C',
      _ => '#24D391',
    };
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HtmlElementView(viewType: _viewType),
        if (_loading || _error != null)
          Positioned.fill(
            child: Container(
              color: const Color(0xFFEAF1EC),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF46515A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

class _AmapWebConfig {
  const _AmapWebConfig({
    this.key = '',
    this.securityJsCode = '',
    this.serviceHost = '',
  });

  final String key;
  final String securityJsCode;
  final String serviceHost;
}
