import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:HolaTalk/views/widgets/animations/animated_button.dart';
import 'package:HolaTalk/views/screens/chat/chat_screen.dart';
import 'package:HolaTalk/views/screens/feeds/post_detail.dart'; // PostDetailPage를 임포트합니다.

class ProfilePage extends StatefulWidget {
  final String userId;
  final ScrollController scrollController;

  ProfilePage({required this.userId, required this.scrollController});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static Random random = Random();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _profileImageUrl;
  String? _userName;
  String? _currentUserId;
  int _postCount = 0;
  int _followerCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    await _loadProfileImage();
    await _loadUserName();
    await _loadPostCount();
    await _loadFollowCounts();
    await _checkIfFollowing();
  }

  Future<void> _loadProfileImage() async {
    try {
      final ref = _storage.ref().child('user_profile/${widget.userId}.heic');
      final url = await ref.getDownloadURL();
      setState(() {
        _profileImageUrl = url;
      });
    } catch (e) {
      print('Failed to load user profile image: $e');
    }
  }

  Future<void> _loadUserName() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      setState(() {
        _userName = userDoc.data()?['name'];
      });
    } catch (e) {
      print('Failed to load user name: $e');
    }
  }

  Future<void> _loadPostCount() async {
    try {
      final postQuery = await _firestore
          .collection('moments')
          .where('userId', isEqualTo: widget.userId)
          .get();
      setState(() {
        _postCount = postQuery.size;
      });
    } catch (e) {
      print('Failed to load post count: $e');
    }
  }

  Future<void> _loadFollowCounts() async {
    try {
      final followerQuery = await _firestore.collection('followers').doc(widget.userId).collection('userFollowers').get();
      final followingQuery = await _firestore.collection('following').doc(widget.userId).collection('userFollowing').get();
      setState(() {
        _followerCount = followerQuery.size;
        _followingCount = followingQuery.size;
      });
    } catch (e) {
      print('Failed to load follow counts: $e');
    }
  }

  Future<void> _checkIfFollowing() async {
    try {
      final doc = await _firestore
          .collection('followers')
          .doc(widget.userId)
          .collection('userFollowers')
          .doc(_currentUserId)
          .get();
      setState(() {
        _isFollowing = doc.exists;
      });
    } catch (e) {
      print('Failed to check following status: $e');
    }
  }

  Future<void> _followUser() async {
    try {
      await _firestore.collection('followers').doc(widget.userId).collection('userFollowers').doc(_currentUserId).set({});
      await _firestore.collection('following').doc(_currentUserId).collection('userFollowing').doc(widget.userId).set({});
      setState(() {
        _isFollowing = true;
        _followerCount += 1;
      });
    } catch (e) {
      print('Failed to follow user: $e');
    }
  }

  Future<void> _unfollowUser() async {
    try {
      await _firestore.collection('followers').doc(widget.userId).collection('userFollowers').doc(_currentUserId).delete();
      await _firestore.collection('following').doc(_currentUserId).collection('userFollowing').doc(widget.userId).delete();
      setState(() {
        _isFollowing = false;
        _followerCount -= 1;
      });
    } catch (e) {
      print('Failed to unfollow user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCurrentUser = widget.userId == _currentUserId;

    return Scaffold(
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 60),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child: _profileImageUrl == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey,
                          )
                        : CachedNetworkImage(
                            imageUrl: _profileImageUrl!,
                            imageBuilder: (context, imageProvider) => CircleAvatar(
                              radius: 50,
                              backgroundImage: imageProvider,
                            ),
                            placeholder: (context, url) => CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                _userName ?? "Unknown User",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Status should be here",
                style: TextStyle(),
              ),
              if (!isCurrentUser) ...[
                SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AnimatedButton(
                      label: "Message",
                      color: Colors.grey,
                      textColor: Colors.white,
                      onPressed: () {
                        // 상대방과의 채팅방 ID를 생성
                        List<String> ids = [_currentUserId!, widget.userId];
                        ids.sort();
                        String chatId = ids.join("_");

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              chatId: chatId,
                              recipientId: widget.userId,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 10),
                    AnimatedButton(
                      label: _isFollowing ? "Unfollow" : "Follow",
                      color: Theme.of(context).colorScheme.secondary,
                      textColor: Colors.white,
                      onPressed: () {
                        if (_isFollowing) {
                          _unfollowUser();
                        } else {
                          _followUser();
                        }
                      },
                    ),
                  ],
                ),
              ],
              SizedBox(height: 40),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _buildCategory("Posts", _postCount),
                    _buildCategory("Followers", _followerCount),
                    _buildCategory("Following", _followingCount),
                  ],
                ),
              ),
              SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('moments')
                    .where('userId', isEqualTo: widget.userId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final posts = snapshot.data!.docs;

                  if (posts.isEmpty) {
                    return Center(child: Text('No posts yet.'));
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(5),
                    itemCount: posts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 200 / 200,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      var post = posts[index];
                      var imageUrl = post['imageUrl'] ?? '';
                      var content = post['content'] ?? '';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailPage(
                                postId: post.id,
                                userId: widget.userId,
                                name: _userName ?? 'Unknown User',
                                time: (post['createdAt'] as Timestamp).toDate(),
                                img: imageUrl,
                                content: content,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(3.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Color(0xFFEEF7FF),
                            ),
                            child: imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        content.length > 50 ? '${content.substring(0, 50)}...' : content,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(String title, int count) {
    return Column(
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(),
        ),
      ],
    );
  }
}
