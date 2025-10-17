import 'package:flutter/material.dart';

class ChatListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Yapping',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CircleAvatar(
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Matches',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  RecentMatch(name: 'Selena', imageUrl: 'https://i.pravatar.cc/150?img=32'),
                  RecentMatch(name: 'Selena', imageUrl: 'https://i.pravatar.cc/150?img=33'),
                  RecentMatch(name: 'Clara', imageUrl: 'https://i.pravatar.cc/150?img=35'),
                  RecentMatch(name: 'Fabian', imageUrl: 'https://i.pravatar.cc/150?img=60'),
                  RecentMatch(name: 'George', imageUrl: 'https://i.pravatar.cc/150?img=59'),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(top: 24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: ListView(
                  children: [
                    ChatItem(
                      name: 'Alfredo Calzoni',
                      message: 'What about that new jacket if I _',
                      time: '09:18',
                      imageUrl: 'https://i.pravatar.cc/150?img=68',
                      hasUnread: true,
                    ),
                    ChatItem(
                      name: 'Clara Hazel',
                      message: 'I know right 😉',
                      time: '12:44',
                      imageUrl: 'https://i.pravatar.cc/150?img=35',
                      hasUnread: true,
                    ),
                    ChatItem(
                      name: 'Brandon Aminoff',
                      message: "I've already registered, can't wai...",
                      time: '08:06',
                      imageUrl: 'https://i.pravatar.cc/150?img=63',
                      hasUnread: true,
                    ),
                    ChatItem(
                      name: 'Amina Mina',
                      message: 'It will have two lines of heading ...',
                      time: '09:32',
                      imageUrl: 'https://i.pravatar.cc/150?img=49',
                      hasUnread: false,
                    ),
                     ChatItem(
                      name: 'Savanna Hall',
                      message: 'It will have two lines of heading ...',
                      time: '06:21',
                      imageUrl: 'https://i.pravatar.cc/150?img=50',
                      hasUnread: false,
                    ),
                     ChatItem(
                      name: 'Sara Grif',
                      message: 'Oh come on!! Is it really that gre...',
                      time: '05:01',
                      imageUrl: 'https://i.pravatar.cc/150?img=45',
                      hasUnread: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentMatch extends StatelessWidget {
  final String name;
  final String imageUrl;

  RecentMatch({required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: NetworkImage(imageUrl),
          ),
          SizedBox(height: 8.0),
          Text(
            name,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class ChatItem extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final String imageUrl;
  final bool hasUnread;

  ChatItem({
    required this.name,
    required this.message,
    required this.time,
    required this.imageUrl,
    required this.hasUnread,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(imageUrl),
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message, style: TextStyle(color: Colors.grey)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(time, style: TextStyle(color: Colors.grey)),
          if (hasUnread)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}