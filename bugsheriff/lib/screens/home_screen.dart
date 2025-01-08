import 'package:flutter/material.dart';
import '../left_sidebar.dart'; // LeftSidebar'ı import edin

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BugSheriff Bug Bounty Platform'), // Başlık
      ),
      drawer: LeftSidebar(), // Sol yan menüyü burada ekleyin
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'The Bug Bounty Program is an initiative that invites hackers and security researchers to find and report vulnerabilities in our systems. By identifying potential security issues, we aim to improve the overall safety of our platform and protect our users. Participants are rewarded for their findings, creating a collaborative approach to security enhancement.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20), // Resim ile açıklama arasında boşluk

            Image.asset(
              'assets/default.jfif', // Resim dosyasının yolu
              height: 400, // Resmin yüksekliği
            ),
          ],
        ),
      ),
    );
  }
}
