import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../student/my_purchases.dart';

class MySalesPage extends StatelessWidget {
  final User user;

  const MySalesPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return OrdersListPage(
      title: 'My Sales',
      user: user,
      buyerView: false,
    );
  }
}
