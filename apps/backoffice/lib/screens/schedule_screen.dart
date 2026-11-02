import 'package:flutter/material.dart';
import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs/src/moji_zakupi/zakupi_bloc.dart';
import 'package:backoffice/backoffice_shortcuts.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>{

  ZakupId? _selectedReservationId;
  final FocusNode _mainFocusNode=FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<ZakupiBloc>().add(const ZatrazeniZakupi());
  }

  @override
  void dispose() {
    _mainFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build (BuildContext context){
    return Scaffold(
      appBar: AppBar(
          title: const Text('Backoffice - Raspored i zakupi'),
          actions: [
            IconButton(
            icon:const Icon(Icons.bug_report_outlined),
            tooltip: 'Simuliraj grešku',
            onPressed:(){

              context.read<ZakupRepository>().simulirajGresku();
              context.read<ZakupiBloc>().add(const ZatrazeniZakupi());
            },

            )],
      ),
      body:BackofficeShortcuts(
        focusNode: _mainFocusNode,
        selectedId: _selectedReservationId,
        onSelectionChanged: (newId) {
          setState(() {
            _selectedReservationId = newId;
          });
        },

      child: BlocConsumer<ZakupiBloc, ZakupiState>(
        listener: (context, state) {

          if (state is ZakupiUcitani && state.obavestenje != null) {
            final obavestenje = state.obavestenje;
            String poruka = '';

            if (obavestenje is ZakupOtkazan) {
              poruka = 'Zakup je uspešno otkazan.';
            } else if (obavestenje is ZakupOdobren) {
              poruka = 'Zakup je uspešno odobren.';
            }else if (obavestenje is OtkazivanjeOdbijeno) {
              poruka = 'Greška pri otkazivanju: ${obavestenje.greska}';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(poruka),
                width: 320,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 2),
              ),
            );


            context.read<ZakupiBloc>().add(const ObavestenjePotvrdjeno());
          }
        },
        builder: (context, state) {
          return switch (state) {
            ZakupiUcitavanje() => const Center(
              child: CircularProgressIndicator(),
            ),
            ZakupiPrazno() => const Center(
              child: Text('Trenutno nema zakupa.'),
            ),
            ZakupiGreska(:final greska) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    switch (greska) {
                      ZakupVecPoceo() => 'Došlo je do greške: Mrežna greška.',
                      NedozvoljenPrelaz(:final od, :final ka) => 'Nedozvoljen prelaz iz ${od.runtimeType} u ${ka.runtimeType}.',
                      _ => 'Došlo je do neočekivane greške.',
                    },
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ZakupiBloc>().add(const ZatrazeniZakupi());
                    },
                    child: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            ),
            ZakupiUcitani(:final zakupi, :final otkazivanje) => LayoutBuilder(

              builder:(context, constraints) {

               final isUzakEkran = constraints.maxWidth < 800;

               if(isUzakEkran){
                 return Column(
                   children: [
                     Expanded(
                         flex: 1,
                         child: ListView.separated(
                           itemCount: zakupi.length,
                           separatorBuilder:(_, __) => const Divider(height: 1),
                           itemBuilder: (context,index){
                             final zakup = zakupi[index];
                             final isSelected = zakup.id == _selectedReservationId;
                             final d = zakup.datumOd;

                             return ListTile(
                               selected:isSelected ,
                               selectedTileColor: Colors.blue.shade50,
                               title: Text(
                                 '${zakup.predmet.naziv} (#${zakup.id})',
                                 style: const TextStyle(fontWeight: FontWeight.bold),
                               ),
                               subtitle: Text(
                                 'Datum: ${d.day}.${d.month}.${d.year}. | Status: ${zakup.status.runtimeType}',
                               ),
                               onTap:(){
                                 setState(() {
                                   if(_selectedReservationId==zakup.id){
                                     _selectedReservationId=null;
                                   }else{
                                     _selectedReservationId=zakup.id;
                                   }
                                 });
                               } ,
                             );

                           },
                         )

                     ),
                     const Divider(height: 1, thickness: 2),
                     Expanded(
                      flex:1,
                      child: _buildDetailsPanel(zakupi, otkazivanje),
                     ),


                   ],
                 );
               }

               return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Klijent')),
                          DataColumn(label: Text('Datum')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: zakupi.map((zakup) {
                          final isSelected = zakup.id == _selectedReservationId;
                          final d = zakup.datumOd;
                          final datumStr = '${d.day}.${d.month}.${d.year}.';
                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: (_) {
                              setState(() {
                                if (_selectedReservationId == zakup.id) {
                                  _selectedReservationId = null;
                                } else {
                                  _selectedReservationId = zakup.id;
                                }
                              });
                            },
                            cells: [
                              DataCell(Text(zakup.id.toString())),
                              DataCell(Text(zakup.predmet.naziv)),
                              DataCell(Text(datumStr)),
                              DataCell(Text(zakup.status.runtimeType.toString())),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 1,
                    child: _buildDetailsPanel(zakupi, otkazivanje),
                  ),
                ],
               );
              }
            ),
          };
        },
      ),
      )
    );
  }


  Widget _buildDetailsPanel(List<Zakup> zakupi, ZakupId? otkazivanjeUToeku) {
    if (_selectedReservationId == null) {
      return const Center(
        child: Text(
          'Izaberite zakup iz tabele za prikaz detalja',
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
      );
    }

    final selectedIndex = zakupi.indexWhere((z) => z.id == _selectedReservationId);

    if (selectedIndex == -1) {
      return const Center(
        child: Text(
          'Izabrani zakup više ne postoji.',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    final selectedItem = zakupi[selectedIndex];
    final isOtkazivanjeInProgres = otkazivanjeUToeku == selectedItem.id;

    final dOd = selectedItem.datumOd;
    final dDo = selectedItem.datumDo;

    final mozeSePotvrditi = selectedItem.status is Zahtev;
    final mozeSeOtkazati = selectedItem.status is Zahtev || selectedItem.status is Odobren || selectedItem.status is Placen;
    final isSporan = selectedItem.status is Sporan;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalji zakupa #${selectedItem.id}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Predmet'),
            subtitle: Text(selectedItem.predmet.naziv, style: const TextStyle(fontSize: 16)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Period zakupa'),
            subtitle: Text(
              '${dOd.day}.${dOd.month}.${dOd.year}. - ${dDo.day}.${dDo.month}.${dDo.year}. (${selectedItem.brojDana} dana)',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Status'),
            subtitle: Text(selectedItem.status.runtimeType.toString(), style: const TextStyle(fontSize: 16)),
          ),
          if (isSporan) ...[
            const Divider(),
            const Text(
              'Otvoren spor - Poređenje fotografija:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Preuzimanje', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: const Center(
                          child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 36),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Vraćanje (Oštećenje)', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.red, size: 36),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                    onPressed: () {
                      context.read<ZakupiBloc>().add(
                        PromenaStatusaZakupa(
                          id: selectedItem.id,
                          noviStatus: const Zavrsen(),
                        ),
                      );
                    },
                    child: const Text('Vrati depozit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                    onPressed: () {
                      context.read<ZakupiBloc>().add(
                        PromenaStatusaZakupa(
                          id: selectedItem.id,
                          noviStatus: const Zavrsen(),
                        ),
                      );
                    },
                    child: const Text('Naplati depozit', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),
          if (isOtkazivanjeInProgres)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: mozeSePotvrditi
                        ? () {
                      context.read<ZakupiBloc>().add(
                        PromenaStatusaZakupa(
                          id: selectedItem.id,
                          noviStatus: const Odobren(),
                        ),
                      );
                    }
                        : null,
                    child: const Text('Potvrdi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: mozeSeOtkazati
                        ? () {
                      context.read<ZakupiBloc>().add(
                        OtkazivanjeZakupa(selectedItem.id),
                      );
                    }
                        : null,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Otkaži'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
