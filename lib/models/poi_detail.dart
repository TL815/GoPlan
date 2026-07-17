/// 扩展的POI详情模型，对应高德POI API返回的完整字段
class PoiDetail {
  const PoiDetail({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.typecode,
    this.address,
    this.tel,
    this.province,
    this.city,
    this.district,
    this.rating,
    this.cost,
    this.openTime,
    this.photos = const [],
    this.tags = const [],
    this.businessArea,
    this.entranceLocation,
    this.alias,
    this.website,
    this.indoorMap = false,
  });

  // 基础字段
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String category;

  // 高德扩展字段
  final String? typecode; // 分类编码 如 141201
  final String? address; // 详细地址
  final String? tel; // 电话
  final String? province; // 省份
  final String? city; // 城市
  final String? district; // 区县
  final String? rating; // 评分 如 "4.8"
  final String? cost; // 人均消费/门票价格
  final String? openTime; // 开放时间
  final List<String> photos; // 图片URL列表
  final List<String> tags; // 特色标签
  final String? businessArea; // 所属商圈
  final String? entranceLocation; // 入口经纬度
  final String? alias; // 别名
  final String? website; // 官网
  final bool indoorMap; // 是否有室内地图

  /// 从高德POI API JSON解析
  factory PoiDetail.fromAmapJson(Map<String, dynamic> json) {
    final bizExt = json['biz_ext'] as Map<String, dynamic>?;
    final photoList = json['photos'] as List<dynamic>?;
    final tagStr = json['tag'] as String?;

    return PoiDetail(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: _parseLat(json['location'] as String?),
      longitude: _parseLng(json['location'] as String?),
      category: _categoryFromTypecode(json['typecode'] as String?),
      typecode: json['typecode'] as String?,
      address: json['address'] as String?,
      tel: json['tel'] as String?,
      province: json['pname'] as String?,
      city: json['cityname'] as String?,
      district: json['adname'] as String?,
      rating: bizExt?['rating'] as String?,
      cost: bizExt?['cost'] as String?,
      openTime: json['open_time'] as String?,
      photos:
          photoList
              ?.map((p) => (p as Map<String, dynamic>)['url'] as String?)
              .where((url) => url != null)
              .cast<String>()
              .toList() ??
          const [],
      tags: tagStr?.split(',').map((t) => t.trim()).toList() ?? const [],
      businessArea: json['business_area'] as String?,
      entranceLocation: json['entr_location'] as String?,
      alias: json['alias'] as String?,
      website: json['website'] as String?,
      indoorMap: json['indoor_map'] == '1',
    );
  }

  /// 从经纬度字符串解析纬度
  static double _parseLat(String? location) {
    if (location == null || !location.contains(',')) return 0;
    return double.tryParse(location.split(',')[1]) ?? 0;
  }

  /// 从经纬度字符串解析经度
  static double _parseLng(String? location) {
    if (location == null || !location.contains(',')) return 0;
    return double.tryParse(location.split(',')[0]) ?? 0;
  }

  /// 从高德typecode映射到GoPlan分类
  static String _categoryFromTypecode(String? typecode) {
    if (typecode == null) return 'other';
    final prefix = typecode.substring(0, 2);
    switch (prefix) {
      case '14':
        return 'scenic'; // 风景名胜
      case '05':
        return 'food'; // 餐饮服务
      case '10':
        return 'hotel'; // 住宿服务
      case '06':
        return 'shopping'; // 购物服务
      case '15':
        return 'transport'; // 交通设施
      default:
        return 'other';
    }
  }

  /// 分类名称（中文）
  String get categoryName {
    switch (category) {
      case 'scenic':
        return '景点';
      case 'food':
        return '美食';
      case 'hotel':
        return '住宿';
      case 'shopping':
        return '购物';
      case 'transport':
        return '交通';
      default:
        return '其他';
    }
  }

  /// 分类色值
  int get categoryColor {
    switch (category) {
      case 'scenic':
        return 0xFF24D391;
      case 'food':
        return 0xFFFFA629;
      case 'hotel':
        return 0xFF4EA9FF;
      case 'shopping':
        return 0xFFFF6BA6;
      case 'transport':
        return 0xFF7BC69C;
      default:
        return 0xFF24D391;
    }
  }

  /// 评分数值
  double? get ratingValue => double.tryParse(rating ?? '');

  /// 是否有图片
  bool get hasPhotos => photos.isNotEmpty;

  /// 是否有电话
  bool get hasTel => tel != null && tel!.isNotEmpty;

  /// 完整地址
  String get fullAddress {
    final parts = <String>[
      if (province != null && province!.isNotEmpty) province!,
      if (city != null && city!.isNotEmpty && city != province) city!,
      if (district != null && district!.isNotEmpty) district!,
      if (address != null && address!.isNotEmpty) address!,
    ];
    return parts.join('');
  }
}
