part of '../../main.dart';

class TravelPlan {
  const TravelPlan({
    required this.title,
    required this.dateRange,
    required this.places,
    required this.members,
    required this.days,
    required this.accent,
    required this.routeStops,
    this.countdown,
  });

  final String title;
  final String dateRange;
  final int places;
  final int members;
  final int days;
  final Color accent;
  final List<RouteStop> routeStops;
  final int? countdown;
}

class RouteStop {
  const RouteStop({required this.label, required this.position});

  final String label;
  final Offset position;
}

const demoPlans = [
  TravelPlan(
    title: '青甘大环线10天游',
    dateRange: '2026.03.24~2026.04.01',
    places: 15,
    members: 4,
    days: 10,
    accent: Color(0xFF69A7FF),
    routeStops: [
      RouteStop(label: '西宁', position: Offset(.12, .64)),
      RouteStop(label: '青海湖', position: Offset(.32, .42)),
      RouteStop(label: '茶卡', position: Offset(.51, .48)),
      RouteStop(label: '敦煌', position: Offset(.7, .26)),
      RouteStop(label: '张掖', position: Offset(.9, .58)),
    ],
  ),
  TravelPlan(
    title: '川西雪山小团行',
    dateRange: '2026.05.02~2026.05.07',
    places: 12,
    members: 6,
    days: 6,
    accent: Color(0xFF7BC69C),
    routeStops: [
      RouteStop(label: '成都', position: Offset(.16, .7)),
      RouteStop(label: '康定', position: Offset(.36, .54)),
      RouteStop(label: '新都桥', position: Offset(.55, .42)),
      RouteStop(label: '塔公', position: Offset(.72, .53)),
      RouteStop(label: '四姑娘山', position: Offset(.88, .28)),
    ],
  ),
  TravelPlan(
    title: '杭州情侣周末游',
    dateRange: '2026.06.12~2026.06.14',
    places: 8,
    members: 2,
    days: 3,
    accent: Color(0xFFFFB35D),
    routeStops: [
      RouteStop(label: '西湖', position: Offset(.16, .35)),
      RouteStop(label: '灵隐', position: Offset(.32, .2)),
      RouteStop(label: '河坊街', position: Offset(.48, .48)),
      RouteStop(label: '滨江', position: Offset(.66, .68)),
      RouteStop(label: '钱江', position: Offset(.86, .56)),
    ],
    countdown: 2,
  ),
  TravelPlan(
    title: '云南朋友毕业旅行',
    dateRange: '2026.07.18~2026.07.26',
    places: 18,
    members: 5,
    days: 9,
    accent: Color(0xFFC48BFF),
    routeStops: [
      RouteStop(label: '昆明', position: Offset(.14, .72)),
      RouteStop(label: '大理', position: Offset(.34, .5)),
      RouteStop(label: '丽江', position: Offset(.55, .34)),
      RouteStop(label: '泸沽湖', position: Offset(.74, .42)),
      RouteStop(label: '香格里拉', position: Offset(.88, .18)),
    ],
    countdown: 38,
  ),
];

class PoiCategory {
  const PoiCategory({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final String icon;
}

const poiCategories = [
  PoiCategory(key: 'scenic', label: '景点', icon: 'assets/icons/景点.png'),
  PoiCategory(key: 'food', label: '美食', icon: 'assets/icons/美食.png'),
  PoiCategory(key: 'hotel', label: '住宿', icon: 'assets/icons/住宿.png'),
  PoiCategory(key: 'shopping', label: '购物', icon: 'assets/icons/购物.png'),
  PoiCategory(key: 'transport', label: '交通', icon: 'assets/icons/交通.png'),
];

class Poi {
  const Poi({
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

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'category': category,
  };
}

const demoPois = [
  Poi(
    id: '1',
    name: '人民广场',
    latitude: 41.8003,
    longitude: 123.4315,
    category: 'scenic',
  ),
  Poi(
    id: '2',
    name: '市府恒隆广场',
    latitude: 41.7959,
    longitude: 123.4377,
    category: 'shopping',
  ),
  Poi(
    id: '3',
    name: '娌堥槼鏁呭',
    latitude: 41.7955,
    longitude: 123.4498,
    category: 'scenic',
  ),
  Poi(
    id: '4',
    name: '张氏帅府',
    latitude: 41.7936,
    longitude: 123.4510,
    category: 'scenic',
  ),
  Poi(
    id: '5',
    name: '北陵公园',
    latitude: 41.8268,
    longitude: 123.4249,
    category: 'scenic',
  ),
  Poi(
    id: '6',
    name: '中街步行街',
    latitude: 41.7970,
    longitude: 123.4525,
    category: 'shopping',
  ),
  Poi(
    id: '7',
    name: '老边饺子',
    latitude: 41.7978,
    longitude: 123.4480,
    category: 'food',
  ),
  Poi(
    id: '8',
    name: '沈阳站',
    latitude: 41.7890,
    longitude: 123.4100,
    category: 'transport',
  ),
  Poi(
    id: '9',
    name: '万达文华酒店',
    latitude: 41.7920,
    longitude: 123.4420,
    category: 'hotel',
  ),
];
