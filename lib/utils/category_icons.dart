import 'package:flutter/material.dart';

class CategoryIcons {
  // Maps category icon string → MaterialIcon
  static IconData resolve(String icon) {
    switch (icon) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'bills':
        return Icons.home_rounded;
      case 'entertainment':
        return Icons.sports_esports_rounded;
      case 'health':
        return Icons.local_hospital_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      // Custom category icons by name
      case 'star':
        return Icons.star_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'pet':
        return Icons.pets_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'food2':
        return Icons.local_pizza_rounded;
      case 'laptop':
        return Icons.laptop_rounded;
      case 'beach':
        return Icons.beach_access_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'baby':
        return Icons.child_care_rounded;
      case 'sport':
        return Icons.sports_soccer_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // Icon options shown in category picker
  static const List<Map<String, dynamic>> pickerIcons = [
    {'key': 'star', 'icon': Icons.star_rounded},
    {'key': 'fitness', 'icon': Icons.fitness_center_rounded},
    {'key': 'travel', 'icon': Icons.flight_rounded},
    {'key': 'education', 'icon': Icons.school_rounded},
    {'key': 'pet', 'icon': Icons.pets_rounded},
    {'key': 'book', 'icon': Icons.menu_book_rounded},
    {'key': 'music', 'icon': Icons.music_note_rounded},
    {'key': 'food2', 'icon': Icons.local_pizza_rounded},
    {'key': 'laptop', 'icon': Icons.laptop_rounded},
    {'key': 'beach', 'icon': Icons.beach_access_rounded},
    {'key': 'gift', 'icon': Icons.card_giftcard_rounded},
    {'key': 'coffee', 'icon': Icons.coffee_rounded},
    {'key': 'baby', 'icon': Icons.child_care_rounded},
    {'key': 'sport', 'icon': Icons.sports_soccer_rounded},
    {'key': 'shopping', 'icon': Icons.shopping_bag_rounded},
    {'key': 'health', 'icon': Icons.local_hospital_rounded},
  ];
}
