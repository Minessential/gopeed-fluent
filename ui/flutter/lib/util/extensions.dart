import 'dart:core';
import 'package:checkable_treeview_fluent/checkable_treeview.dart';
import 'package:flutter/widgets.dart';
import '../api/model/resource.dart';
import '../app/views/file_icon.dart';
import 'util.dart';

extension ListFileInfoExtension on List<FileInfo> {
  List<FluentTreeNode<int>> toTreeNodes() {
    final List<FluentTreeNode<int>> rootNodes = [];
    final Map<String, FluentTreeNode<int>> dirNodes = {};
    var nodeIndex = 0;

    for (var i = 0; i < length; i++) {
      final file = this[i];
      final parts = file.path.split('/');
      String currentPath = '';
      FluentTreeNode<int>? parentNode;

      // Create or get directory nodes
      for (final part in parts) {
        if (part.isEmpty) continue;

        currentPath += '/$part';
        if (!dirNodes.containsKey(currentPath)) {
          final node = FluentTreeNode<int>(
            value: nodeIndex++,
            label: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(file.name), Text(Util.fmtByte(file.size))],
            ),
            icon: Icon(fileIcon(part, isFolder: true), size: 18),
            children: [],
          );
          dirNodes[currentPath] = node;

          if (parentNode == null) {
            rootNodes.add(node);
          } else {
            parentNode.children.add(node);
          }
        }
        parentNode = dirNodes[currentPath];
      }

      // Create file node using file.name
      final fileNode = FluentTreeNode<int>(
        value: nodeIndex++,
        label: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(file.name), Text(Util.fmtByte(file.size))],
        ),
        icon: Icon(fileIcon(file.name, isFolder: false), size: 18),
        children: [],
      );

      // Add file node to parent or root
      if (parentNode != null) {
        parentNode.children.add(fileNode);
      } else {
        rootNodes.add(fileNode);
      }
    }

    return rootNodes;
  }
}
