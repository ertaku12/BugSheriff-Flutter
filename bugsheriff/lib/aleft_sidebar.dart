import 'package:flutter/material.dart';

class aLeftSidebar extends StatelessWidget {
  const aLeftSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            title: Text('Admin\'s Home'),
            onTap: () {
              Navigator.pushNamed(context, '/ahome');
            },
          ),
          ListTile(
            title: Text('Login'),
            onTap: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
          ListTile(
            title: Text('Sign Up'),
            onTap: () {
              Navigator.pushNamed(context, '/signup');
            },
          ),
          ListTile(
            title: Text('Admin\'s Profile'),
            onTap: () {
              Navigator.pushNamed(context, '/aprofile');
            },
          ),
          ListTile(
            title: Text('Admin\'s Programs'),
            onTap: () {
              Navigator.pushNamed(context, '/aprograms');
            },
          ),
          ListTile(
            title: Text('Admin\'s Reports'),
            onTap: () {
              Navigator.pushNamed(context, '/areports');
            },
          ),
        ],
      ),
    );
  }
}
