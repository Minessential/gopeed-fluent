import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';

class CheckListView extends StatefulWidget {
  final List<String> items;
  final List<String> checked;
  final void Function(List<String> value) onChanged;

  const CheckListView({
    Key? key,
    required this.items,
    required this.checked,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CheckListView> createState() => _CheckListView();
}

class _CheckListView extends State<CheckListView> {
  bool get _allChecked => _checked.length == _items.length;

  List<String> get _checked => widget.checked;

  List<String> get _items => widget.items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile.selectable(
                selectionMode: ListTileSelectionMode.multiple,
                selected: _checked.contains(item),
                onSelectionChange: (value) {
                  setState(() {
                    _checked.contains(item) ? _checked.remove(item) : _checked.add(item);
                    widget.onChanged(_checked);
                  });
                },
                title: Text(item),
              );
            },
          ),
        ),
        ListTile.selectable(
          selectionMode: ListTileSelectionMode.multiple,
          selected: _allChecked,
          onSelectionChange: (value) {
            setState(() {
              _checked.clear();
              if (value) _checked.addAll(_items);
              widget.onChanged(_checked);
            });
          },
          title: Text('selectAll'.tr),
        ),
      ],
    );
  }
}
