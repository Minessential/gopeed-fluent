import 'package:checkable_treeview_fluent/checkable_treeview.dart';
import 'package:fluent_ui/fluent_ui.dart' hide ToggleSwitch;
import 'package:get/get.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../api/model/resource.dart';
import '../../icon/gopeed_icons.dart';
import '../../util/util.dart';
import 'file_icon.dart';
import 'responsive_builder.dart';
import 'sort_icon_button.dart';

const _toggleSwitchIcons = [Gopeed.file_video, Gopeed.file_audio, Gopeed.file_image];
const _sizeGapWidth = 72.0;

class FileTreeView extends StatefulWidget {
  final List<FileInfo> files;
  final List<int> initialValues;
  final Function(List<int>) onSelectionChanged;

  const FileTreeView({Key? key, required this.files, required this.initialValues, required this.onSelectionChanged})
    : super(key: key);

  @override
  State<FileTreeView> createState() => _FileTreeViewState();
}

class _FileTreeViewState extends State<FileTreeView> {
  late GlobalKey<FluentTreeViewState<int>> key;
  late int totalSize;
  int? toggleSwitchIndex;

  @override
  void initState() {
    super.initState();
    key = GlobalKey<FluentTreeViewState<int>>();
    totalSize = widget.files.fold(0, (previousValue, element) => previousValue + element.size);
    widget.onSelectionChanged(widget.initialValues);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    final selectedFileCount =
        key.currentState?.getSelectedValues().where((e) => e != null).length ?? widget.files.length;
    final selectedFileSize = calcSelectedSize(null);

    final filterRow = ToggleSwitch(
      minHeight: 32,
      cornerRadius: 4,
      doubleTapDisable: true,
      inactiveBgColor: theme.resources.dividerStrokeColorDefault,
      activeBgColor: [theme.accentColor],
      initialLabelIndex: toggleSwitchIndex,
      icons: _toggleSwitchIcons,
      onToggle: (index) {
        toggleSwitchIndex = index;
        if (index == null) {
          key.currentState?.setSelectedValues(List.empty());
          return;
        }

        final iconFileExtArr = iconConfigMap[_toggleSwitchIcons[index]] ?? [];
        final selectedFileIndexes = widget.files
            .asMap()
            .entries
            .where((e) => iconFileExtArr.contains(fileExt(e.value.name)))
            .map((e) => e.key)
            .toList();
        key.currentState?.setSelectedValues(selectedFileIndexes);
      },
    );
    final countRow = Row(
      children: [
        Text('fileSelectedCount'.tr),
        Text(selectedFileCount.toString(), style: theme.typography.bodyStrong),
        const SizedBox(width: 12),
        Text('fileSelectedSize'.tr),
        Text(
          selectedFileCount > 0 && selectedFileSize == 0 ? 'unknown'.tr : Util.fmtByte(selectedFileSize),
          style: theme.typography.bodyStrong,
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.resources.dividerStrokeColorDefault),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FluentTreeView(
              key: key,
              nodes: buildTreeNodes(),
              showExpandCollapseButton: true,
              showSelectAll: true,
              onSelectionChanged: (selectedValues) {
                setState(() {});
                widget.onSelectionChanged(selectedValues.where((e) => e != null).map((e) => e!).toList());
              },
              selectAllTrailing: (context) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SortIconButton(
                      label: 'name'.tr,
                      onStateChanged: (state) {
                        switch (state) {
                          case SortState.asc:
                            key.currentState?.sort((p0, p1) {
                              return (p0.label as Text).data!.compareTo((p1.label as Text).data!);
                            });
                            break;
                          case SortState.desc:
                            key.currentState?.sort((p0, p1) {
                              return (p1.label as Text).data!.compareTo((p0.label as Text).data!);
                            });
                            break;
                          default:
                            key.currentState?.sort(null);
                            break;
                        }
                      },
                    ),
                    SortIconButton(
                      label: 'size'.tr,
                      onStateChanged: (state) {
                        switch (state) {
                          case SortState.asc:
                            key.currentState?.sort((p0, p1) {
                              return calcSelectedSize(p0).compareTo(calcSelectedSize(p1));
                            });
                            break;
                          case SortState.desc:
                            key.currentState?.sort((p0, p1) {
                              return calcSelectedSize(p1).compareTo(calcSelectedSize(p0));
                            });
                            break;
                          default:
                            key.currentState?.sort(null);
                            break;
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        !ResponsiveBuilder.isNarrow(context)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [filterRow, countRow],
              )
            : Column(spacing: 8, crossAxisAlignment: CrossAxisAlignment.start, children: [filterRow, countRow]),
      ],
    );
  }

  int calcSelectedSize(FluentTreeNode<int>? node) {
    if (key.currentState == null) {
      return widget.files.fold(0, (previousValue, element) => previousValue + element.size);
    }

    final selectedFileIndexes = node == null
        ? key.currentState?.getSelectedValues()
        : (node.value != null ? [node.value] : key.currentState?.getChildSelectedValues(node));

    if (selectedFileIndexes == null) return 0;
    return selectedFileIndexes
        .where((e) => e != null)
        .map((e) => e!)
        .fold(0, (previousValue, element) => previousValue + widget.files[element].size);
  }

  List<FluentTreeNode<int>> buildTreeNodes() {
    final List<FluentTreeNode<int>> rootNodes = [];
    final Map<String, FluentTreeNode<int>> dirNodes = {};

    for (var i = 0; i < widget.files.length; i++) {
      final file = widget.files[i];
      final parts = file.path.split('/');
      String currentPath = '';
      FluentTreeNode<int>? parentNode;

      // Create or get directory nodes
      for (final part in parts) {
        if (part.isEmpty) continue;

        currentPath += '/$part';
        if (!dirNodes.containsKey(currentPath)) {
          final node = FluentTreeNode<int>(
            label: Text(part),
            icon: Icon(fileIcon(part, isFolder: true), size: 18),
            trailing: (context, node) {
              final size = calcSelectedSize(node);
              return size > 0
                  ? Text(Util.fmtByte(calcSelectedSize(node)), style: FluentTheme.of(context).typography.caption)
                  : const SizedBox(width: _sizeGapWidth);
            },
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
        label: Text(file.name),
        value: i,
        icon: Icon(fileIcon(file.name, isFolder: false), size: 18),
        trailing: (context, node) {
          return file.size > 0
              ? Text(Util.fmtByte(file.size), style: FluentTheme.of(context).typography.caption)
              : const SizedBox(width: _sizeGapWidth);
        },
        isSelected: widget.initialValues.contains(i),
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
