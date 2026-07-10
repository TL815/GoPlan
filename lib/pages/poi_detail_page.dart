import 'package:flutter/material.dart';
import '../models/poi_detail.dart';

/// 景点详情页 - 展示POI完整信息
/// 基于高德POI API返回的完整字段构建
class PoiDetailPage extends StatelessWidget {
  const PoiDetailPage({super.key, required this.poi});

  final PoiDetail poi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: CustomScrollView(
        slivers: [
          // 顶部大图区域
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1C1C1E),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 图片或占位背景
                  Container(
                    color: Color(poi.categoryColor),
                    child: poi.hasPhotos
                        ? Image.network(
                            poi.photos.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  // 底部渐变遮罩
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: .7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 标题信息
                  Positioned(
                    bottom: 16,
                    left: 18,
                    right: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 分类标签
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(poi.categoryColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            poi.categoryName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          poi.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (poi.alias != null && poi.alias!.isNotEmpty)
                          Text(
                            '别名：${poi.alias}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .7),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 内容区域
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 评分与价格卡片
                  _buildInfoCard(),
                  const SizedBox(height: 16),

                  // 地址信息
                  _buildSectionTitle('地址'),
                  _buildInfoRow(Icons.location_on_outlined, poi.fullAddress),
                  if (poi.businessArea != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 32, top: 4),
                      child: Text(
                        '所属商圈：${poi.businessArea}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 电话
                  if (poi.hasTel) ...[
                    _buildSectionTitle('电话'),
                    _buildInfoRow(Icons.phone_outlined, poi.tel!),
                    const SizedBox(height: 16),
                  ],

                  // 开放时间
                  if (poi.openTime != null && poi.openTime!.isNotEmpty) ...[
                    _buildSectionTitle('开放时间'),
                    _buildInfoRow(
                      Icons.access_time_outlined,
                      poi.openTime!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 门票/消费
                  if (poi.cost != null && poi.cost!.isNotEmpty) ...[
                    _buildSectionTitle(
                      poi.category == 'food' ? '人均消费' : '门票价格',
                    ),
                    _buildInfoRow(
                      poi.category == 'food'
                          ? Icons.restaurant_outlined
                          : Icons.confirmation_num_outlined,
                      '¥${poi.cost}',
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 特色标签
                  if (poi.tags.isNotEmpty) ...[
                    _buildSectionTitle('特色'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: poi.tags
                          .map((tag) => _buildTagChip(tag))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 图片画廊
                  if (poi.hasPhotos) ...[
                    _buildSectionTitle('图片'),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: poi.photos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              poi.photos[index],
                              width: 160,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 160,
                                height: 120,
                                color: const Color(0xFFE0E0E0),
                                child: const Icon(Icons.image,
                                    color: Color(0xFFBBBBBB)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 坐标信息（调试用，正式环境可隐藏）
                  _buildSectionTitle('位置坐标'),
                  _buildInfoRow(
                    Icons.gps_fixed_outlined,
                    '${poi.latitude.toStringAsFixed(4)}, ${poi.longitude.toStringAsFixed(4)}',
                  ),

                  // 底部安全区
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      // 底部操作按钮
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_location_alt_outlined,
                      size: 18),
                  label: const Text('加入行程'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C1C1E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined,
                      color: Color(0xFF4C4C4C)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: const Center(
        child: Icon(Icons.image, size: 60, color: Color(0xFFBBBBBB)),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 评分
          if (poi.rating != null) ...[
            _buildStatItem(
              Icons.star_rounded,
              poi.rating!,
              '评分',
              const Color(0xFFF7B733),
            ),
            const SizedBox(width: 24),
          ],
          // 分类
          _buildStatItem(
            Icons.category_outlined,
            poi.categoryName,
            '类型',
            Color(poi.categoryColor),
          ),
          const SizedBox(width: 24),
          // 室内地图
          _buildStatItem(
            poi.indoorMap
                ? Icons.map_outlined
                : Icons.map_outlined,
            poi.indoorMap ? '支持' : '暂无',
            '室内地图',
            const Color(0xFF999999),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C1C1E),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1C1C1E),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF999999)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4C4C4C),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF4C4C4C),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
