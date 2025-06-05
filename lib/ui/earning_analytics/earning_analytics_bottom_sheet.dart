import 'package:aktau_go/core/images.dart';
import 'package:aktau_go/core/text_styles.dart';
import 'package:aktau_go/domains/user/user_domain.dart';
import 'package:aktau_go/ui/widgets/primary_bottom_sheet.dart';
import 'package:aktau_go/utils/num_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';

class EarningAnalyticsBottomSheet extends StatefulWidget {
  final UserDomain? me;

  const EarningAnalyticsBottomSheet({Key? key, required this.me}) : super(key: key);

  @override
  State<EarningAnalyticsBottomSheet> createState() => _EarningAnalyticsBottomSheetState();
}

class _EarningAnalyticsBottomSheetState extends State<EarningAnalyticsBottomSheet> {
  String _selectedTimeFrame = 'Week';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle for dragging
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              Icon(Icons.monetization_on, size: 28, color: primaryColor),
              SizedBox(width: 12),
              Text(
                'Аналитика заработка',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
            ),
          ),
            ],
          ),
          SizedBox(height: 20),
          
          // Time frame selector
          Container(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTimeFrameButton('День', _selectedTimeFrame == 'Day'),
                _buildTimeFrameButton('Неделя', _selectedTimeFrame == 'Week'),
                _buildTimeFrameButton('Месяц', _selectedTimeFrame == 'Month'),
                _buildTimeFrameButton('Год', _selectedTimeFrame == 'Year'),
              ],
            ),
          ),
          SizedBox(height: 20),
          
          // Earnings summary cards
          Row(
              children: [
                Expanded(
                child: _buildSummaryCard(
                  'Всего заказов',
                  '${(widget.me?.ordersToday ?? 0) + (widget.me?.ordersThisWeek ?? 0) + (widget.me?.ordersThisMonth ?? 0)}',
                  Icons.assignment,
                  Colors.blue.shade50,
                  Colors.blue,
                          ),
                        ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Общий доход',
                  '${_calculateTotalEarnings()} ₸',
                  Icons.attach_money,
                  Colors.green.shade50,
                  Colors.green,
                          ),
                        ),
                      ],
                    ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Рейтинг',
                  '${widget.me?.rating.toStringAsFixed(1) ?? 0.0}',
                  Icons.star,
                  Colors.amber.shade50,
                  Colors.amber,
                  ),
                ),
              SizedBox(width: 16),
                Expanded(
                child: _buildSummaryCard(
                  'Отзывы',
                  '${widget.me?.ratedOrders.length ?? 0}',
                  Icons.rate_review,
                  Colors.purple.shade50,
                  Colors.purple,
                          ),
                        ),
                      ],
                    ),
          SizedBox(height: 24),
          
          // Chart section
          Text(
            'Динамика дохода',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 200,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _buildEarningsChart(),
          ),
          SizedBox(height: 24),
          
          // Recent orders section
          Text(
            'Недавние поездки',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 200,
            child: widget.me?.ratedOrders != null && 
                  (widget.me?.ratedOrders.isNotEmpty ?? false) 
                ? ListView.builder(
                    itemCount: min(widget.me!.ratedOrders.length, 5),
                    itemBuilder: (context, index) {
                      final order = widget.me!.ratedOrders[index];
                      return ListTile(
                        leading: Icon(Icons.directions_car, color: primaryColor),
                        title: Text(
                          '${order.from ?? ""} → ${order.to ?? ""}',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(order.createdAt != null 
                          ? DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt!)
                          : ""),
                        trailing: Text(
                          '${order.price ?? 0} ₸',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Нет завершенных поездок',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
          SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildTimeFrameButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeFrame = text == 'День' ? 'Day' : 
                               text == 'Неделя' ? 'Week' :
                               text == 'Месяц' ? 'Month' : 'Year';
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
            child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
          Icon(icon, color: iconColor, size: 28),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
                          ),
                        ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildEarningsChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = 'Пн';
                    break;
                  case 2:
                    text = 'Ср';
                    break;
                  case 4:
                    text = 'Пт';
                    break;
                  case 6:
                    text = 'Вс';
                    break;
                  default:
                    text = '';
                }
                return Text(
                  text,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 5,
        lineBarsData: [
          LineChartBarData(
            spots: _generateRandomSpots(),
            isCurved: true,
            color: primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateRandomSpots() {
    // Sample data for demonstration
    return [
      FlSpot(0, 2.5),
      FlSpot(1, 2.1),
      FlSpot(2, 3.2),
      FlSpot(3, 2.8),
      FlSpot(4, 3.5),
      FlSpot(5, 3.2),
      FlSpot(6, 4.1),
    ];
  }

  int _calculateTotalEarnings() {
    int total = 0;
    
    // Use the income statistics available in UserDomain
    if (widget.me != null) {
      total = (widget.me!.today + widget.me!.thisWeek + widget.me!.thisMonth).toInt();
    }
    
    return total;
  }
  
  int min(int a, int b) {
    return a < b ? a : b;
  }
}
