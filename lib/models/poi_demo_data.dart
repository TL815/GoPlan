import 'poi_detail.dart';

/// 沈阳故宫 - 完整POI示例数据
/// 模拟高德POI API返回的完整字段
const shenyangGugong = PoiDetail(
  id: 'B0FFG6L7Q8',
  name: '沈阳故宫',
  latitude: 41.7955,
  longitude: 123.4498,
  category: 'scenic',
  typecode: '141201',
  address: '沈阳市沈河区沈阳路171号',
  tel: '024-24843001',
  province: '辽宁省',
  city: '沈阳市',
  district: '沈河区',
  rating: '4.7',
  cost: '50.00',
  openTime: '4月10日-10月10日 08:30-17:30（16:45停止入场）\n'
      '10月11日-4月9日 09:00-16:30（15:45停止入场）\n'
      '每周一闭馆（法定节假日除外）',
  photos: [
    'https://picsum.photos/400/300?random=1',
    'https://picsum.photos/400/300?random=2',
    'https://picsum.photos/400/300?random=3',
  ],
  tags: ['世界遗产', '清朝皇宫', '4A景区', '古建筑', '历史文化'],
  businessArea: '中街/故宫',
  entranceLocation: '123.4498,41.7955',
  alias: '盛京皇宫',
  website: 'https://www.sypm.org.cn',
  indoorMap: true,
);

/// 人民广场 - 另一个景点示例
const renminSquare = PoiDetail(
  id: 'B0FFH8M9K2',
  name: '人民广场',
  latitude: 41.8003,
  longitude: 123.4315,
  category: 'scenic',
  typecode: '141202',
  address: '沈阳市沈河区市府大路',
  tel: '',
  province: '辽宁省',
  city: '沈阳市',
  district: '沈河区',
  rating: '4.5',
  cost: '0.00',
  openTime: '全天开放',
  photos: [],
  tags: ['城市地标', '广场', '免费开放'],
  businessArea: '市府广场',
  entranceLocation: '',
  alias: '',
  website: '',
  indoorMap: false,
);

/// 北陵公园 - 景点示例
const beilingPark = PoiDetail(
  id: 'B0FFJ1N4P6',
  name: '北陵公园',
  latitude: 41.8268,
  longitude: 123.4249,
  category: 'scenic',
  typecode: '141203',
  address: '沈阳市皇姑区泰山路12号',
  tel: '024-86896294',
  province: '辽宁省',
  city: '沈阳市',
  district: '皇姑区',
  rating: '4.6',
  cost: '5.00',
  openTime: '07:00-17:00',
  photos: [
    'https://picsum.photos/400/300?random=4',
  ],
  tags: ['清昭陵', '世界文化遗产', '4A景区', '园林'],
  businessArea: '北陵',
  entranceLocation: '123.4249,41.8268',
  alias: '清昭陵',
  website: '',
  indoorMap: false,
);

/// 张氏帅府 - 景点示例
const zhangShuaiFu = PoiDetail(
  id: 'B0FFK2O5Q7',
  name: '张氏帅府',
  latitude: 41.7936,
  longitude: 123.4510,
  category: 'scenic',
  typecode: '141201',
  address: '沈阳市沈河区朝阳街少帅府巷46号',
  tel: '024-24850576',
  province: '辽宁省',
  city: '沈阳市',
  district: '沈河区',
  rating: '4.6',
  cost: '48.00',
  openTime: '08:30-17:00（16:30停止入场）\n每周一闭馆',
  photos: [
    'https://picsum.photos/400/300?random=5',
    'https://picsum.photos/400/300?random=6',
  ],
  tags: ['民国建筑', '张学良故居', '4A景区', '博物馆'],
  businessArea: '中街/故宫',
  entranceLocation: '123.4510,41.7936',
  alias: '大帅府',
  website: 'https://www.zhangxueliang.org.cn',
  indoorMap: true,
);

/// 所有示例POI列表
const List<PoiDetail> demoPoiDetails = [
  shenyangGugong,
  renminSquare,
  beilingPark,
  zhangShuaiFu,
];
