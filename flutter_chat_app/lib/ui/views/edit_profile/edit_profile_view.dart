import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'edit_profile_viewmodel.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<EditProfileViewModel>.reactive(
      viewModelBuilder: EditProfileViewModel.new,
      builder: (BuildContext context, EditProfileViewModel viewModel, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: viewModel.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: viewModel.isBusy
                        ? null
                        : () async {
                            final bool saved = await viewModel.save();
                            if (context.mounted && saved) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
