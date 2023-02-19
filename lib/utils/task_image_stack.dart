import 'dart:io';

import 'package:flutter/material.dart';
import 'package:to_do_app/models/task_image.dart';

class TaskImageStack extends StatelessWidget {
  final TaskImage taskImage;

  const TaskImageStack({
    required this.taskImage,
    Key? key,
  }) : super(key: key);

  get direction => null;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: FileImage(File(taskImage.imagePath)),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black12, spreadRadius: 0.5),
            ],
            gradient: const LinearGradient(
              colors: [Colors.black12, Colors.black87],
              begin: Alignment.center,
              stops: [0.4, 1],
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                left: 0,
                bottom: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildUserInfo(taskImage: taskImage),
                    // buildLikeBadge(direction: direction),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16, right: 8),
                      child: Icon(Icons.info, color: Colors.white),
                    )
                  ],
                ),
              ),
            ],
          ),
        ));
  }

/*
  Widget buildLikeBadge({required CardSwiperDirection? direction}) {
    if (direction?.name == 'right') {
      return Positioned(
          child: Transform.rotate(
        angle: 0.5,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: const Text(
            'Right',
            style: TextStyle(
              color: Colors.green,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ));
    } else if (direction?.name == 'left') {
      return Positioned(
          child: Transform.rotate(
        angle: 0.5,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.pink, width: 2),
          ),
          child: const Text(
            'Left',
            style: TextStyle(
              color: Colors.pink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ));
    } else if (direction?.name == 'top') {
      return Positioned(
          child: Transform.rotate(
        angle: 0.5,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.pink, width: 2),
          ),
          child: const Text(
            'Top',
            style: TextStyle(
              color: Colors.pink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ));
    } else {
      return Visibility(
        visible: false,
        child: Container(),
      );
    }
  }
*/
  Widget buildUserInfo({required TaskImage taskImage}) => Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Task ID: ${taskImage.taskId.toString()}\nUploaded: ${taskImage.uploadDate.replaceRange(18, 25, '')}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );
}
