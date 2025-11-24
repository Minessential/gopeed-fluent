import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gopeed/app/views/filled_button_loading.dart';
import 'package:gopeed/app/views/fluent/base_pane_body.dart';
import 'package:gopeed/app/views/fluent/universal_scroll_view.dart';
import 'package:gopeed/theme/theme.dart';
import 'package:path/path.dart' as path;

import '../../../../api/api.dart';
import '../../../../api/model/create_task.dart';
import '../../../../api/model/create_task_batch.dart';
import '../../../../api/model/options.dart';
import '../../../../api/model/request.dart';
import '../../../../api/model/resolve_result.dart';
import '../../../../api/model/task.dart';
import '../../../../database/database.dart';
import '../../../../util/input_formatter.dart';
import '../../../../util/message.dart';
import '../../../../util/util.dart';
import '../../../routes/app_pages.dart';
import '../../../views/directory_selector.dart';
import '../../../views/file_tree_view.dart';
import '../../app/controllers/app_controller.dart';
import '../../history/views/history_view.dart';
import '../controllers/create_controller.dart';

class CreateView extends GetView<CreateController> {
  final _confirmFormKey = GlobalKey<FormState>();

  final _urlController = TextEditingController();
  final _renameController = TextEditingController();
  final _connectionsController = TextEditingController();
  final _pathController = TextEditingController();
  final _confirmController = FilledButtonLoadingController();
  final _proxyIpController = TextEditingController();
  final _proxyPortController = TextEditingController();
  final _proxyUsrController = TextEditingController();
  final _proxyPwdController = TextEditingController();
  final _httpHeaderControllers = [
    (name: TextEditingController(text: "User-Agent"), value: TextEditingController()),
    (name: TextEditingController(text: "Cookie"), value: TextEditingController()),
    (name: TextEditingController(text: "Referer"), value: TextEditingController()),
  ];
  final _btTrackerController = TextEditingController();

  final _availableSchemes = ["http:", "https:", "magnet:"];

  final _skipVerifyCertController = false.obs;

  CreateView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();

    if (_connectionsController.text.isEmpty) {
      _connectionsController.text = appController.downloaderConfig.value.protocolConfig.http.connections.toString();
    }
    if (_pathController.text.isEmpty) {
      _pathController.text = appController.downloaderConfig.value.downloadDir;
    }

    final CreateTask? routerParams = Get.rootDelegate.arguments();
    if (routerParams?.req?.url.isNotEmpty ?? false) {
      // get url from route arguments
      final url = routerParams!.req!.url;
      _urlController.text = url;
      _urlController.selection = TextSelection.fromPosition(TextPosition(offset: _urlController.text.length));
      final protocol = parseProtocol(url);
      if (protocol != null) {
        final extraHandlers = {
          Protocol.http: () {
            final reqExtra = ReqExtraHttp.fromJson(jsonDecode(jsonEncode(routerParams.req!.extra)));
            _httpHeaderControllers.clear();
            reqExtra.header.forEach((key, value) {
              _httpHeaderControllers.add((
                name: TextEditingController(text: key),
                value: TextEditingController(text: value),
              ));
            });
            _skipVerifyCertController.value = routerParams.req!.skipVerifyCert;
          },
          Protocol.bt: () {
            final reqExtra = ReqExtraBt.fromJson(jsonDecode(jsonEncode(routerParams.req!.extra)));
            _btTrackerController.text = reqExtra.trackers.join("\n");
          },
        };
        if (routerParams.req?.extra != null) {
          extraHandlers[protocol]?.call();
        }

        // handle options
        if (routerParams.opt != null) {
          _renameController.text = routerParams.opt!.name;
          _pathController.text = routerParams.opt!.path;

          final optionsHandlers = {
            Protocol.http: () {
              final opt = routerParams.opt!;
              _renameController.text = opt.name;
              _pathController.text = opt.path;
              if (opt.extra != null) {
                final optsExtraHttp = OptsExtraHttp.fromJson(jsonDecode(jsonEncode(opt.extra)));
                _connectionsController.text = optsExtraHttp.connections.toString();
              }
            },
            Protocol.bt: null,
          };
          if (routerParams.opt?.extra != null) {
            optionsHandlers[protocol]?.call();
          }
        }
      }
    } else if (_urlController.text.isEmpty) {
      // read clipboard
      Clipboard.getData('text/plain').then((value) {
        if (value?.text?.isNotEmpty ?? false) {
          if (_availableSchemes
              .where((e) => value!.text!.startsWith(e) || value.text!.startsWith(e.toUpperCase()))
              .isNotEmpty) {
            _urlController.text = value!.text!;
            _urlController.selection = TextSelection.fromPosition(TextPosition(offset: _urlController.text.length));
            return;
          }

          recognizeMagnetUri(value!.text!);
        }
      });
    }

    return DropTarget(
      onDragDone: (details) async {
        if (!Util.isWeb()) {
          _urlController.text = details.files[0].path;
          return;
        }
        _urlController.text = details.files[0].name;
        final bytes = await details.files[0].readAsBytes();
        controller.setFileDataUri(bytes);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: BasePaneBody(
          title: 'create'.tr,
          body: Form(
            key: _confirmFormKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: UniversalScrollView(
              spacing: 16,
              children: [
                _FormRow(
                  icon: FluentIcons.link_24_regular,
                  label: 'downloadLink'.tr,
                  trailing: [
                    buildFormItemIcon(
                      icon: FluentIcons.folder_open_16_regular,
                      onPressed: () async {
                        var pr = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ["torrent"],
                        );
                        if (pr != null) {
                          if (!Util.isWeb()) {
                            _urlController.text = pr.files[0].path ?? "";
                            return;
                          }
                          _urlController.text = pr.files[0].name;
                          controller.setFileDataUri(pr.files[0].bytes!);
                        }
                      },
                    ),
                    buildFormItemIcon(
                      icon: FluentIcons.history_20_regular,
                      onPressed: () async {
                        final theme = FluentTheme.of(context);
                        List<String> resultOfHistories = Database.instance.getCreateHistory() ?? [];
                        // show dialog box to list history
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return HistoryView(
                                isHistoryListEmpty: resultOfHistories.isEmpty,
                                historyList: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: resultOfHistories.length,
                                  itemBuilder: (context, index) {
                                    return HoverButton(
                                      cursor: SystemMouseCursors.click,
                                      onPressed: () {
                                        _urlController.text = resultOfHistories[index];
                                        Get.back();
                                      },
                                      builder: (context, state) {
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          decoration: ShapeDecoration(
                                            color: getCardBackgroundColor(theme).resolve(state),
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide(color: theme.resources.cardStrokeColorDefault),
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(6.0),
                                                bottom: Radius.circular(6.0),
                                              ),
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Text(resultOfHistories[index]),
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ],
                  child: TextFormBox(
                    autofocus: !Util.isMobile(),
                    controller: _urlController,
                    minLines: 1,
                    maxLines: 5,
                    placeholder: _hitText(),
                    suffixMode: OverlayVisibilityMode.editing,
                    suffix: IconButton(
                      onPressed: () {
                        _urlController.clear();
                        controller.clearFileDataUri();
                      },
                      icon: const Icon(FluentIcons.dismiss_12_regular),
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    validator: (v) {
                      return v!.trim().isNotEmpty ? null : 'downloadLinkValid'.tr;
                    },
                    onChanged: (v) async {
                      controller.clearFileDataUri();
                      if (controller.oldUrl.value.isEmpty) {
                        recognizeMagnetUri(v);
                      }
                      controller.oldUrl.value = v;
                    },
                  ),
                ),
                _FormRow(
                  label: 'rename'.tr,
                  child: TextBox(controller: _renameController),
                ),
                _FormRow(
                  label: 'connections'.tr,
                  child: TextBox(
                    controller: _connectionsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      NumericalRangeFormatter(min: 1, max: 256),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 44.0),
                  child: DirectorySelector(controller: _pathController),
                ),

                Obx(
                  () => Visibility(
                    visible: controller.showAdvanced.value,
                    child: Column(
                      spacing: 12,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormRow(
                          icon: FluentIcons.server_link_20_regular,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 150,
                              child: ComboBox<RequestProxyMode>(
                                placeholder: Text('proxy'.tr),
                                isExpanded: true,
                                value: controller.proxyConfig.value?.mode,
                                onChanged: (value) async {
                                  if (value != null) {
                                    controller.proxyConfig.value = RequestProxy()..mode = value;
                                  }
                                },
                                items: [
                                  ComboBoxItem<RequestProxyMode>(
                                    value: RequestProxyMode.follow,
                                    child: Text('followSettings'.tr),
                                  ),
                                  ComboBoxItem<RequestProxyMode>(
                                    value: RequestProxyMode.none,
                                    child: Text('noProxy'.tr),
                                  ),
                                  ComboBoxItem<RequestProxyMode>(
                                    value: RequestProxyMode.custom,
                                    child: Text('customProxy'.tr),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ...(controller.proxyConfig.value?.mode == RequestProxyMode.custom
                            ? [
                                Container(
                                  width: 150,
                                  margin: const EdgeInsets.only(left: 44),
                                  child: ComboBox<String>(
                                    isExpanded: true,
                                    value: controller.proxyConfig.value?.scheme,
                                    onChanged: (value) async {
                                      if (value != null) controller.proxyConfig.value?.scheme = value;
                                    },
                                    items: const [
                                      ComboBoxItem<String>(value: 'http', child: Text('HTTP')),
                                      ComboBoxItem<String>(value: 'https', child: Text('HTTPS')),
                                      ComboBoxItem<String>(value: 'socks5', child: Text('SOCKS5')),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    const SizedBox(width: 44),
                                    Flexible(
                                      child: InfoLabel(
                                        label: 'server'.tr,
                                        child: TextFormBox(controller: _proxyIpController),
                                      ),
                                    ),
                                    const Padding(padding: EdgeInsets.only(left: 10)),
                                    Flexible(
                                      child: InfoLabel(
                                        label: 'port'.tr,
                                        child: TextFormBox(
                                          controller: _proxyPortController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            NumericalRangeFormatter(min: 0, max: 65535),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const SizedBox(width: 44),
                                    Flexible(
                                      child: InfoLabel(
                                        label: 'username'.tr,
                                        child: TextFormBox(controller: _proxyUsrController),
                                      ),
                                    ),
                                    const Padding(padding: EdgeInsets.only(left: 10)),
                                    Flexible(
                                      child: InfoLabel(
                                        label: 'password'.tr,
                                        child: TextFormBox(controller: _proxyPwdController),
                                      ),
                                    ),
                                  ],
                                ),
                              ]
                            : const []),
                        const Divider(),
                        Container(
                          width: 150,
                          margin: const EdgeInsets.only(left: 44),
                          child: ComboBox<int>(
                            isExpanded: true,
                            value: controller.advancedTabIndex.value,
                            onChanged: (value) async {
                              if (value != null) controller.updateAdvancedTabIndex(value);
                            },
                            items: const [
                              ComboBoxItem<int>(value: 0, child: Text('HTTP')),
                              ComboBoxItem<int>(value: 1, child: Text('BitTorrent')),
                            ],
                          ),
                        ),
                        if (controller.advancedTabIndex.value == 0)
                          ..._httpHeaderControllers.map((e) {
                            return Row(
                              children: [
                                const SizedBox(width: 44),
                                Flexible(
                                  child: TextFormBox(controller: e.name, placeholder: 'httpHeaderName'.tr),
                                ),
                                const SizedBox(width: 10),

                                Flexible(
                                  child: TextFormBox(controller: e.value, placeholder: 'httpHeaderValue'.tr),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(FluentIcons.add_20_regular, size: 18),
                                  onPressed: () {
                                    _httpHeaderControllers.add((
                                      name: TextEditingController(),
                                      value: TextEditingController(),
                                    ));
                                    controller.showAdvanced.update((val) => val);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(FluentIcons.subtract_20_regular, size: 18),
                                  onPressed: () {
                                    if (_httpHeaderControllers.length <= 1) {
                                      return;
                                    }
                                    _httpHeaderControllers.remove(e);
                                    controller.showAdvanced.update((val) => val);
                                  },
                                ),
                              ],
                            );
                          }),
                        if (controller.advancedTabIndex.value == 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 44),
                            child: Checkbox(
                              content: Text('skipVerifyCert'.tr),
                              checked: _skipVerifyCertController.value,
                              onChanged: (bool? value) {
                                _skipVerifyCertController.value = value ?? false;
                              },
                            ),
                          ),
                        if (controller.advancedTabIndex.value == 1)
                          _FormRow(
                            label: 'Trackers',
                            child: TextFormBox(
                              controller: _btTrackerController,
                              maxLines: 5,
                              placeholder: 'addTrackerHit'.tr,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    spacing: 16,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => Checkbox(
                          content: Text('directDownload'.tr),
                          checked: controller.directDownload.value,
                          onChanged: (bool? value) {
                            controller.directDownload.value = value ?? false;
                          },
                        ),
                      ),
                      Obx(
                        () => Checkbox(
                          checked: controller.showAdvanced.value,
                          onChanged: (bool? value) {
                            controller.showAdvanced.value = value ?? false;
                          },
                          content: Text('advancedOptions'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 150,
                    child: FilledButtonLoading(
                      onPressed: () => _doConfirm(context),
                      controller: _confirmController,
                      child: Text('confirm'.tr),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // parse protocol from url
  parseProtocol(String url) {
    final uppercaseUrl = url.toUpperCase();
    Protocol? protocol;
    if (uppercaseUrl.startsWith("HTTP:") || uppercaseUrl.startsWith("HTTPS:")) {
      protocol = Protocol.http;
    }
    if (uppercaseUrl.startsWith("MAGNET:") || uppercaseUrl.endsWith(".TORRENT")) {
      protocol = Protocol.bt;
    }
    return protocol;
  }

  // recognize magnet uri, if length == 40, auto add magnet prefix
  recognizeMagnetUri(String text) {
    if (text.length != 40) {
      return;
    }
    final exp = RegExp(r"[0-9a-fA-F]+");
    if (exp.hasMatch(text)) {
      final uri = "magnet:?xt=urn:btih:$text";
      _urlController.text = uri;
      _urlController.selection = TextSelection.fromPosition(TextPosition(offset: _urlController.text.length));
    }
  }

  Future<void> _doConfirm(BuildContext context) async {
    if (controller.isConfirming.value) {
      return;
    }
    controller.isConfirming.value = true;
    try {
      _confirmController.start();
      if (_confirmFormKey.currentState!.validate()) {
        final isWebFileChosen = Util.isWeb() && controller.fileDataUri.isNotEmpty;
        final submitUrl = isWebFileChosen ? controller.fileDataUri.value : _urlController.text.trim();

        final urls = Util.textToLines(submitUrl);
        // Add url to the history
        if (!isWebFileChosen) {
          for (final url in urls) {
            Database.instance.saveCreateHistory(url);
          }
        }

        /*
        Check if is direct download, there has two ways to direct download
        1. Direct download option is checked
        2. Muli line urls
        */
        final isMultiLine = urls.length > 1;
        final isDirect = controller.directDownload.value || isMultiLine;
        if (isDirect) {
          await Future.wait(
            urls.map((url) {
              return createTask(
                CreateTask(
                  req: Request(
                    url: url,
                    extra: parseReqExtra(url),
                    proxy: parseProxy(),
                    skipVerifyCert: _skipVerifyCertController.value,
                  ),
                  opt: Options(
                    name: isMultiLine ? "" : _renameController.text,
                    path: _pathController.text,
                    selectFiles: [],
                    extra: parseReqOptsExtra(),
                  ),
                ),
              );
            }),
          );
          Get.rootDelegate.offNamed(Routes.TASK);
        } else {
          final rr = await resolve(
            Request(
              url: submitUrl,
              extra: parseReqExtra(_urlController.text),
              proxy: parseProxy(),
              skipVerifyCert: _skipVerifyCertController.value,
            ),
          );
          if (context.mounted) await _showResolveDialog(context, rr);
        }
      }
    } catch (e) {
      if (context.mounted) showErrorMessage(context, e);
    } finally {
      _confirmController.stop();
      controller.isConfirming.value = false;
    }
  }

  RequestProxy? parseProxy() {
    if (controller.proxyConfig.value?.mode == RequestProxyMode.custom) {
      return RequestProxy()
        ..mode = RequestProxyMode.custom
        ..scheme = _proxyIpController.text
        ..host = "${_proxyIpController.text}:${_proxyPortController.text}"
        ..usr = _proxyUsrController.text
        ..pwd = _proxyPwdController.text;
    }
    return controller.proxyConfig.value;
  }

  Object? parseReqExtra(String url) {
    Object? reqExtra;
    final protocol = parseProtocol(url);
    switch (protocol) {
      case Protocol.http:
        final header = Map<String, String>.fromEntries(
          _httpHeaderControllers.map((e) => MapEntry(e.name.text, e.value.text)),
        );
        header.removeWhere((key, value) => key.trim().isEmpty || value.trim().isEmpty);
        if (header.isNotEmpty) {
          reqExtra = ReqExtraHttp()..header = header;
        }
        break;
      case Protocol.bt:
        if (_btTrackerController.text.trim().isNotEmpty) {
          reqExtra = ReqExtraBt()..trackers = Util.textToLines(_btTrackerController.text);
        }
        break;
    }
    return reqExtra;
  }

  Object? parseReqOptsExtra() {
    return OptsExtraHttp()
      ..connections = int.tryParse(_connectionsController.text) ?? 0
      ..autoTorrent = true;
  }

  String _hitText() {
    return 'downloadLinkHit'.trParams({'append': Util.isDesktop() || Util.isWeb() ? 'downloadLinkHitDesktop'.tr : ''});
  }

  Future<void> _showResolveDialog(BuildContext context, ResolveResult rr) async {
    final createFormKey = GlobalKey<FormState>();
    final downloadController = FilledButtonLoadingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        title: rr.res.name.isEmpty ? null : Text(rr.res.name),
        content: Form(
          key: createFormKey,
          autovalidateMode: AutovalidateMode.always,
          child: FileTreeView(
            files: rr.res.files,
            initialValues: rr.res.files.asMap().keys.toList(),
            onSelectionChanged: (List<int> values) {
              controller.selectedIndexes.value = values;
            },
          ),
        ),
        actions: [
          Obx(
            () => FilledButtonLoading(
              onPressed: controller.selectedIndexes.isNotEmpty
                  ? () async {
                      try {
                        downloadController.start();
                        final optExtra = parseReqOptsExtra();
                        if (createFormKey.currentState!.validate()) {
                          if (rr.id.isEmpty) {
                            // from extension resolve result
                            final reqs = controller.selectedIndexes.map((index) {
                              final file = rr.res.files[index];
                              return CreateTaskBatchItem(
                                req: file.req!..proxy = parseProxy(),
                                opts: Options(
                                  name: file.name,
                                  path: path.join(_pathController.text, rr.res.name, file.path),
                                  selectFiles: [],
                                  extra: optExtra,
                                ),
                              );
                            }).toList();
                            await createTaskBatch(CreateTaskBatch(reqs: reqs));
                          } else {
                            await createTask(
                              CreateTask(
                                rid: rr.id,
                                opt: Options(
                                  name: _renameController.text,
                                  path: _pathController.text,
                                  selectFiles: controller.selectedIndexes,
                                  extra: optExtra,
                                ),
                              ),
                            );
                          }
                          Get.back();
                          Get.rootDelegate.offNamed(Routes.TASK);
                        }
                      } catch (e) {
                        if (context.mounted) showErrorMessage(context, e);
                      } finally {
                        downloadController.stop();
                      }
                    }
                  : null,
              controller: downloadController,
              child: Text('download'.tr),
            ),
          ),
          Button(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({this.icon, this.label, required this.child, this.trailing});

  final IconData? icon;
  final String? label;
  final Widget child;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        buildFormItemIcon(icon: icon, haveLabel: label != null),
        Expanded(
          child: label != null ? InfoLabel(label: label!, child: child) : child,
        ),
        ...?trailing,
      ],
    );
  }
}

Widget buildFormItemIcon({IconData? icon, VoidCallback? onPressed, bool haveLabel = true}) {
  Widget buildContent() {
    if (icon == null) return const SizedBox(width: 32);
    if (onPressed == null) {
      return Container(width: 32, height: 32, alignment: Alignment.center, child: Icon(icon, size: 20));
    }
    return IconButton(icon: Icon(icon, size: 20), onPressed: onPressed);
  }

  if (!haveLabel) return buildContent();
  return Container(padding: const EdgeInsets.only(top: 18), child: buildContent());
}
