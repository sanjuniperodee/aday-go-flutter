import 'package:aktau_go/core/colors.dart';
import 'package:aktau_go/core/text_styles.dart';
import 'package:aktau_go/domains/food/food_category_domain.dart';
import 'package:aktau_go/domains/food/food_domain.dart';
import 'package:aktau_go/ui/basket/basket_screen.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:aktau_go/utils/num_utils.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../../core/button_styles.dart';
import '../../widgets/pretty_wave_button.dart';

class TenantHomeFoodsView extends StatefulWidget {
  final ScrollController scrollController;
  final List<FoodCategoryDomain> foodCategories;
  final List<FoodDomain> foods;
  final VoidCallback onScrollDown;

  const TenantHomeFoodsView({
    super.key,
    required this.scrollController,
    required this.foodCategories,
    required this.foods,
    required this.onScrollDown,
  });

  @override
  State<TenantHomeFoodsView> createState() => _TenantHomeFoodsViewState();
}

class _TenantHomeFoodsViewState extends State<TenantHomeFoodsView> {
  int currentTab = 0;
  PageController _pageController = PageController();
  final controller = AutoScrollController();

  List<Map<String, dynamic>> selectedProductQuantity = [];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          // Modern header with shadow
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Категории блюд',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Выберите категорию или добавьте новую',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Categories section with scrollable pills
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                  ),
              ],
                ),
            child: SizedBox(
                  width: double.infinity,
              height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    controller: controller,
                padding: EdgeInsets.symmetric(horizontal: 16),
                    children: [
                  // Add new category button
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddCategoryDialog(context),
                      icon: Icon(Icons.add, size: 18),
                      label: Text('Новая'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  
                  // Category pills
                  for (int index = 0; index < widget.foodCategories.length; index++)
                        AutoScrollTag(
                          index: index,
                          key: Key('category_${index}'),
                          controller: controller,
                      child: Container(
                        margin: EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                currentTab = index;
                              });
                              _pageController.jumpToPage(currentTab);
                            },
                            child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                              color: currentTab == index 
                                  ? primaryColor.withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: currentTab == index
                                    ? primaryColor
                                    : Colors.transparent,
                                width: 1,
                                        ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  widget.foodCategories[index].name,
                                  style: TextStyle(
                                    color: currentTab == index
                                        ? primaryColor
                                        : Colors.black87,
                                    fontWeight: currentTab == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _showEditCategoryDialog(context, index),
                                  child: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: currentTab == index
                                        ? primaryColor
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
          ),
          
          // Content area
                Expanded(
            child: widget.foodCategories.isEmpty
                ? _buildEmptyState()
                : PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        currentTab = page;
                        controller.scrollToIndex(page,
                            preferPosition: AutoScrollPosition.begin);
                      });
                    },
                    children: [
                      for (int j = 0; j < widget.foodCategories.length; j++)
                        _buildCategoryContent(j),
                    ],
                  ),
          ),
          
          // Bottom action bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton.secondary(
                    onPressed: widget.onScrollDown,
                    text: 'Назад',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton.primary(
                    onPressed: selectedProductQuantity.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BasketScreen(
                                  selectedProducts: selectedProductQuantity,
                                ),
                              ),
                            );
                          }
                        : null,
                    text: 'Корзина',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build category content
  Widget _buildCategoryContent(int categoryIndex) {
    final categoryFoods = widget.foods
        .where((food) => food.parentId == widget.foodCategories[categoryIndex].id)
        .toList();
        
    if (categoryFoods.isEmpty) {
      return _buildEmptyCategoryState(categoryIndex);
    }
    
    return ListView.builder(
      padding: EdgeInsets.only(top: 16, bottom: 16),
      itemCount: categoryFoods.length,
      itemBuilder: (context, index) {
        final foodIndex = widget.foods.indexWhere((f) => f.id == categoryFoods[index].id);
        final selectedIndex = selectedProductQuantity.indexWhere(
            (food) => (food['food'] as FoodDomain).id == widget.foods[foodIndex].id);
            
        return _buildFoodItemCard(foodIndex, selectedIndex);
      },
    );
  }
  
  // Empty state placeholder
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            'Нет категорий блюд',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Добавьте новую категорию, чтобы начать',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddCategoryDialog(context),
            icon: Icon(Icons.add),
            label: Text('Добавить категорию'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Empty category state
  Widget _buildEmptyCategoryState(int categoryIndex) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
                          children: [
          Icon(
            Icons.restaurant,
            size: 64,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            'Нет блюд в категории "${widget.foodCategories[categoryIndex].name}"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Добавьте блюда в эту категорию',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {/* Add food to category */},
            icon: Icon(Icons.add),
            label: Text('Добавить блюдо'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Food item card with modern design
  Widget _buildFoodItemCard(int foodIndex, int selectedIndex) {
                                    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Handle item selection
        },
        child: Padding(
          padding: EdgeInsets.all(12),
                                      child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
              // Food image
                                          Container(
                width: 100,
                height: 100,
                                            clipBehavior: Clip.hardEdge,
                                            decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Image.network(
                                              "https://api.aktau-go.kz/img/${widget.foods[foodIndex].id}",
                                              fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.restaurant,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                  ),
                                            ),
                                          ),
              SizedBox(width: 16),
              // Food details
                                          Expanded(
                                            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                    Text(
                      widget.foods[foodIndex].name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.foods[foodIndex].description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                                                  ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    // Price and add button row
                                                Row(
                                                  children: [
                        Text(
                                                        NumUtils.humanizeNumber(
                            widget.foods[foodIndex].price,
                                                              isCurrency: true,
                          ) ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                                                      ),
                                                    ),
                        Spacer(),
                        // Quantity controls
                        if (selectedIndex != -1)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                                                      children: [
                                IconButton(
                                  constraints: BoxConstraints.tight(Size(32, 32)),
                                  icon: Icon(Icons.remove, size: 16),
                                                              onPressed: () {
                                    final newQuantity = selectedProductQuantity[selectedIndex]['quantity'] - 1;
                                    if (newQuantity <= 0) {
                                      setState(() {
                                        selectedProductQuantity.removeAt(selectedIndex);
                                      });
                                    } else {
                                      setState(() {
                                        selectedProductQuantity[selectedIndex] = {
                                          'food': widget.foods[foodIndex],
                                          'quantity': newQuantity,
                                        };
                                      });
                                    }
                                  },
                                ),
                                Text(
                                  '${selectedProductQuantity[selectedIndex]['quantity']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  constraints: BoxConstraints.tight(Size(32, 32)),
                                  icon: Icon(Icons.add, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      selectedProductQuantity[selectedIndex] = {
                                        'food': widget.foods[foodIndex],
                                        'quantity': selectedProductQuantity[selectedIndex]['quantity'] + 1,
                                      };
                                    });
                                  },
                                                            ),
                              ],
                            ),
                          )
                        else
                          IconButton(
                            icon: Icon(Icons.add_circle, color: primaryColor),
                                                            onPressed: () {
                              setState(() {
                                selectedProductQuantity.add({
                                  'food': widget.foods[foodIndex],
                                                                  'quantity': 1,
                                                                });
                              });
                                                            },
                                                        ),
                                                      ],
                    ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
        ),
                                ),
    );
  }
  
  // Add category dialog
  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController categoryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить категорию'),
        content: TextField(
          controller: categoryController,
          decoration: InputDecoration(
            labelText: 'Название категории',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add category logic here
              Navigator.pop(context);
            },
            child: Text('Добавить'),
            style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // Edit category dialog
  void _showEditCategoryDialog(BuildContext context, int categoryIndex) {
    final TextEditingController categoryController = TextEditingController(
      text: widget.foodCategories[categoryIndex].name,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать категорию'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: 'Название категории',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
                  ),
          TextButton(
                  onPressed: () {
              // Delete category logic
              Navigator.pop(context);
            },
            child: Text('Удалить'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
                        ),
                      ),
          ElevatedButton(
            onPressed: () {
              // Update category logic
              Navigator.pop(context);
            },
            child: Text('Сохранить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
                ),
        ],
      ),
    );
  }
}
