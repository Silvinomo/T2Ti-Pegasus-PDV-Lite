/*
Title: T2Ti ERP 3.0                                                                
Description: AbaMestre PersistePage relacionada à tabela [COMPRA_PEDIDO_CABECALHO] 
                                                                                
The MIT License                                                                 
                                                                                
Copyright: Copyright (C) 2021 T2Ti.COM                                          
                                                                                
Permission is hereby granted, free of charge, to any person                     
obtaining a copy of this software and associated documentation                  
files (the "Software"), to deal in the Software without                         
restriction, including without limitation the rights to use,                    
copy, modify, merge, publish, distribute, sublicense, and/or sell               
copies of the Software, and to permit persons to whom the                       
Software is furnished to do so, subject to the following                        
conditions:                                                                     
                                                                                
The above copyright notice and this permission notice shall be                  
included in all copies or substantial portions of the Software.                 
                                                                                
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,                 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES                 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                        
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT                     
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,                    
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING                    
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR                   
OTHER DEALINGS IN THE SOFTWARE.                                                 
                                                                                
       The author may be contacted at:                                          
           t2ti.com@gmail.com                                                   
                                                                                
@author Albert Eije (alberteije@gmail.com)                    
@version 1.0.0
*******************************************************************************/
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:pegasus_pdv/src/database/database.dart';

import 'package:pegasus_pdv/src/database/database_classes.dart';

import 'package:pegasus_pdv/src/infra/infra.dart';
import 'package:pegasus_pdv/src/infra/atalhos_desktop_web.dart';

import 'package:pegasus_pdv/src/view/page/compras/pedido/compra_pedido_cabecalho_page.dart';

import 'package:pegasus_pdv/src/view/shared/caixas_de_dialogo.dart';
import 'package:pegasus_pdv/src/view/shared/view_util_lib.dart';
import 'package:pegasus_pdv/src/view/shared/widgets_abas.dart';
import 'package:pegasus_pdv/src/view/shared/widgets_input.dart';
import 'package:pegasus_pdv/src/view/shared/page/lookup_local_page.dart';

class CompraPedidoCabecalhoPersistePage extends StatefulWidget {
  final CompraPedidoCabecalhoMontado compraPedidoCabecalhoMontado;
  final GlobalKey<FormState> formKey;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final FocusNode foco;
  final Function salvarCompraPedidoCabecalhoCallBack;
  final Function atualizarCompraPedidoCabecalhoCallBack;

  const CompraPedidoCabecalhoPersistePage(
      {Key key, this.formKey, this.scaffoldKey, this.compraPedidoCabecalhoMontado, this.foco, this.salvarCompraPedidoCabecalhoCallBack, this.atualizarCompraPedidoCabecalhoCallBack})
      : super(key: key);

  @override
  _CompraPedidoCabecalhoPersistePageState createState() => _CompraPedidoCabecalhoPersistePageState();
}

class _CompraPedidoCabecalhoPersistePageState extends State<CompraPedidoCabecalhoPersistePage> {
  Map<LogicalKeySet, Intent> _shortcutMap; 
  Map<Type, Action<Intent>> _actionMap;
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _shortcutMap = getAtalhosPersistePage();
    _actionMap = <Type, Action<Intent>>{
      AtalhoTelaIntent: CallbackAction<AtalhoTelaIntent>(
        onInvoke: _tratarAcoesAtalhos,
      ),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarDescontoNosItens());
    _foco.requestFocus();
  }

  void _tratarAcoesAtalhos(AtalhoTelaIntent intent) {
    switch (intent.type) {
      case AtalhoTelaType.salvar:
        widget.salvarCompraPedidoCabecalhoCallBack();
        break;
      default:
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final _valorSubtotalController = MoneyMaskedTextController(precision: Constantes.decimaisValor, initialValue: CompraPedidoCabecalhoPage.compraPedidoCabecalho?.valorSubtotal ?? 0);
    final _importaColaboradorController = TextEditingController();
    _importaColaboradorController.text = widget.compraPedidoCabecalhoMontado.colaborador?.nome ?? '';
    final _taxaDescontoController = MoneyMaskedTextController(precision: Constantes.decimaisTaxa, initialValue: CompraPedidoCabecalhoPage.compraPedidoCabecalho?.taxaDesconto ?? 0);
    final _valorDescontoController = MoneyMaskedTextController(precision: Constantes.decimaisValor, initialValue: CompraPedidoCabecalhoPage.compraPedidoCabecalho?.valorDesconto ?? 0);
    final _valorTotalController = MoneyMaskedTextController(precision: Constantes.decimaisValor, initialValue: CompraPedidoCabecalhoPage.compraPedidoCabecalho?.valorTotal ?? 0);
    final _importaFornecedorController = TextEditingController();
    _importaFornecedorController.text = widget.compraPedidoCabecalhoMontado.fornecedor?.nome ?? '';
    final _diaFixoParcelaController = MaskedTextController(
      mask: Constantes.mascaraDIA,
      text: CompraPedidoCabecalhoPage.compraPedidoCabecalho?.diaFixoParcela ?? '',
    );
    final _intervaloEntreParcelasController = TextEditingController();
    _intervaloEntreParcelasController.text = 
      CompraPedidoCabecalhoPage.compraPedidoCabecalho?.intervaloEntreParcelas == null ? '' : 
      CompraPedidoCabecalhoPage.compraPedidoCabecalho?.intervaloEntreParcelas.toString();

    return FocusableActionDetector(
      actions: _actionMap,
      shortcuts: _shortcutMap,
      child: Focus(
        child: Scaffold(
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "gerarFinanceiro",
                tooltip: 'Gerar Financeiro',
                backgroundColor: Colors.teal,
                child: Icon(Icons.monetization_on),
                onPressed: () async {
                  await _gerarFinanceiro();
                }
              ),            
              SizedBox(
                width: 8,
              ),
              FloatingActionButton(
                heroTag: "atualizarEstoque",
                tooltip: 'Atualiza Estoque',
                backgroundColor: Colors.orange.shade500,
                child: Icon(Icons.category_outlined),
                onPressed: () async {
                  await _atualizarEstoque();
                }
              ),            
          ],),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          drawerDragStartBehavior: DragStartBehavior.down,
          key: widget.scaffoldKey,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Form(
              key: widget.formKey,
              autovalidateMode: AutovalidateMode.always,
              child: Scrollbar(
                child: SingleChildScrollView(
                  dragStartBehavior: DragStartBehavior.down,
                  padding: ViewUtilLib.paddingAbaPersistePage,
                  child: BootstrapContainer(
                    fluid: true,
                    decoration: BoxDecoration(color: Colors.white),
                    padding: Biblioteca.isTelaPequena(context) == true ? ViewUtilLib.paddingBootstrapContainerTelaPequena : ViewUtilLib.paddingBootstrapContainerTelaGrande,                    // children: [
                    children: <Widget>[			  			  
                      Divider(color: Colors.white,),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12',
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    child: TextFormField(
                                      validator: ValidaCampoFormulario.validarObrigatorio,
                                      focusNode: _foco,
                                      controller: _importaColaboradorController,
                                      readOnly: true,
                                      decoration: getInputDecoration(
                                        'Conteúdo para o campo Colaborador',
                                        'Colaborador *',
                                        false),
                                      onSaved: (String value) {
                                      },
                                      onChanged: (text) {
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 0,
                                  child: IconButton(
                                    tooltip: 'Importar Colaborador',
                                    icon: ViewUtilLib.getIconBotaoLookup(),
                                    onPressed: () async {
                                      ///chamando o lookup
                                      Map<String, dynamic> _objetoJsonRetorno =
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                              LookupLocalPage(
                                                title: 'Importar Colaborador',
                                                colunas: ColaboradorDao.colunas,
                                                campos: ColaboradorDao.campos,
                                                campoPesquisaPadrao: 'Nome',
                                                valorPesquisaPadrao: '%',
                                                metodoConsultaCallBack: _filtrarColaboradorLookup,                                             
                                                  ),
                                                  fullscreenDialog: true,
                                                ));
                                      if (_objetoJsonRetorno != null) {
                                        if (_objetoJsonRetorno['nome'] != null) {
                                          _importaColaboradorController.text = _objetoJsonRetorno['nome'];
                                          widget.compraPedidoCabecalhoMontado.colaborador = 
                                            Colaborador(
                                              id: _objetoJsonRetorno['id'],
                                              nome: _objetoJsonRetorno['nome']
                                            );                                
                                          CompraPedidoCabecalhoPage.compraPedidoCabecalho = 
                                            CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(
                                              idColaborador: _objetoJsonRetorno['id']
                                            );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white,),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12',
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    child: TextFormField(
                                      validator: ValidaCampoFormulario.validarObrigatorio,
                                      controller: _importaFornecedorController,
                                      readOnly: true,
                                      decoration: getInputDecoration(
                                        'Conteúdo para o campo Fornecedor',
                                        'Fornecedor *',
                                        false),
                                      onSaved: (String value) {
                                      },
                                      onChanged: (text) {
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 0,
                                  child: IconButton(
                                    tooltip: 'Importar Fornecedor',
                                    icon: ViewUtilLib.getIconBotaoLookup(),
                                    onPressed: () async {
                                      ///chamando o lookup
                                      Map<String, dynamic> _objetoJsonRetorno =
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                              LookupLocalPage(
                                                title: 'Importar Fornecedor',
                                                colunas: FornecedorDao.colunas,
                                                campos: FornecedorDao.campos,
                                                campoPesquisaPadrao: 'Nome',
                                                valorPesquisaPadrao: '%',
                                                metodoConsultaCallBack: _filtrarFornecedorLookup,                                             
                                                  ),
                                                  fullscreenDialog: true,
                                                ));
                                      if (_objetoJsonRetorno != null) {
                                        if (_objetoJsonRetorno['nome'] != null) {
                                          paginaMestreDetalheFoiAlterada = true;
                                          _importaFornecedorController.text = _objetoJsonRetorno['nome'];
                                          widget.compraPedidoCabecalhoMontado.fornecedor = 
                                            Fornecedor(
                                              id: _objetoJsonRetorno['id'],
                                              nome: _objetoJsonRetorno['nome']
                                            );                                
                                          CompraPedidoCabecalhoPage.compraPedidoCabecalho = 
                                            CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(
                                              idFornecedor: _objetoJsonRetorno['id']
                                            );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white,),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(                              
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: InputDecorator(                                                              
                                decoration: getInputDecoration(
                                  '',
                                  'Data do Pedido',
                                  true),
                                isEmpty: CompraPedidoCabecalhoPage.compraPedidoCabecalho.dataPedido == null,
                                child: DatePickerItem(                            
                                  mascara: 'dd/MM/yyyy',
                                  dateTime: CompraPedidoCabecalhoPage.compraPedidoCabecalho.dataPedido,
                                  firstDate: DateTime.parse('1900-01-01'),
                                  lastDate: DateTime.now(),
                                  onChanged: (DateTime value) {
                                    paginaMestreDetalheFoiAlterada = true;
                                    setState(() {
                                      CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(dataPedido: value);
                                      paginaMestreDetalheFoiAlterada = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: InputDecorator(
                                decoration: getInputDecoration(
                                  'Forma de Pagamento',
                                  'Forma de Pagamento',
                                  true, paddingVertical: 1),
                                isEmpty: CompraPedidoCabecalhoPage.compraPedidoCabecalho.formaPagamento == null,
                                child: getDropDownButton(CompraPedidoCabecalhoPage.compraPedidoCabecalho.formaPagamento,
                                  (String newValue) {
                                    paginaMestreDetalheFoiAlterada = true;
                                    setState(() {
                                      CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(formaPagamento: newValue);
                                      paginaMestreDetalheFoiAlterada = true;
                                    });
                                }, <String>[
                                  'Vista',
                                  'Prazo',
                                  'Outros',
                              ])),
                            ),
                          ),
                        
                        ],
                      ),
                      Divider(color: Colors.white,),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: InputDecorator(
                                decoration: getInputDecoration(
                                  '',
                                  'Data Prevista para Entrega',
                                  true),
                                isEmpty: CompraPedidoCabecalhoPage.compraPedidoCabecalho.dataPrevisaoEntrega == null,
                                child: DatePickerItem(
                                  mascara: 'dd/MM/yyyy',
                                  dateTime: CompraPedidoCabecalhoPage.compraPedidoCabecalho.dataPrevisaoEntrega,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.parse('2050-01-01'),
                                  onChanged: (DateTime value) {
                                    paginaMestreDetalheFoiAlterada = true;
                                    setState(() {
                                      CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(dataPrevisaoEntrega: value);
                                      paginaMestreDetalheFoiAlterada = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: InputDecorator(
                                decoration: getInputDecoration(
                                  '',
                                  'Data Previsão Pagamento',
                                  true),
                                isEmpty: CompraPedidoCabecalhoPage.compraPedidoCabecalho.dataPrevisaoPagamento == null,
                                child: DatePickerItem(
                                  mascara: 'dd/MM/yyyy',
                                  dateTime: CompraPedidoCabecalhoPage.compraPedidoCabecalho.dataPrevisaoPagamento,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.parse('2050-01-01'),
                                  onChanged: (DateTime value) {
                                    paginaMestreDetalheFoiAlterada = true;
                                    setState(() {
                                      CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(dataPrevisaoPagamento: value);
                                      paginaMestreDetalheFoiAlterada = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white,),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: InputDecorator(
                                decoration: getInputDecoration(
                                  'Conteúdo para o campo Data Recebimento Itens',
                                  'Data Recebimento Itens',
                                  true),
                                isEmpty: CompraPedidoCabecalhoPage.compraPedidoCabecalho.dataRecebimentoItens == null,
                                child: DatePickerItem(
                                  mascara: 'dd/MM/yyyy',
                                  dateTime: CompraPedidoCabecalhoPage.compraPedidoCabecalho.dataRecebimentoItens,
                                  firstDate: DateTime.parse('1900-01-01'),
                                  lastDate: DateTime.now(),
                                  onChanged: (DateTime value) {
                                    paginaMestreDetalheFoiAlterada = true;
                                    setState(() {
                                      CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(dataRecebimentoItens: value);
                                      paginaMestreDetalheFoiAlterada = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                maxLength: 8,
                                maxLines: 1,
                                initialValue: CompraPedidoCabecalhoPage.compraPedidoCabecalho?.horaRecebimentoItens ?? '',
                                decoration: getInputDecoration(
                                  'Conteúdo para o campo Hora Recebimento Itens',
                                  'Hora Recebimento Itens',
                                  true, paddingVertical: 15),
                                onSaved: (String value) {
                                },
                                onChanged: (text) {
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(horaRecebimentoItens: text);
                                  paginaMestreDetalheFoiAlterada = true;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white,),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                maxLength: 100,
                                maxLines: 1,
                                initialValue: CompraPedidoCabecalhoPage.compraPedidoCabecalho?.localEntrega ?? '',
                                decoration: getInputDecoration(
                                  '',
                                  'Local de Entrega',
                                  false),
                                onSaved: (String value) {
                                },
                                onChanged: (text) {
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(localEntrega: text);
                                  paginaMestreDetalheFoiAlterada = true;
                                },
                              ),
                            ),
                          ),
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                maxLength: 100,
                                maxLines: 1,
                                initialValue: CompraPedidoCabecalhoPage.compraPedidoCabecalho?.localCobranca ?? '',
                                decoration: getInputDecoration(
                                  '',
                                  'Local de Cobrança',
                                  false),
                                onSaved: (String value) {
                                },
                                onChanged: (text) {
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(localCobranca: text);
                                  paginaMestreDetalheFoiAlterada = true;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white,),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12 col-md-3',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                enableInteractiveSelection: !Biblioteca.isDesktop(),
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                textAlign: TextAlign.end,
                                controller: _valorSubtotalController,
                                decoration: getInputDecoration(
                                  '',
                                  'Valor Subtotal',
                                  false,
                                  cor: ViewUtilLib.getTextFieldReadOnlyColor()),
                                onSaved: (String value) {
                                },
                                onChanged: (text) {
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(valorSubtotal: _valorSubtotalController.numberValue);
                                  paginaMestreDetalheFoiAlterada = true;
                                },
                              ),
                            ),
                          ),
                          BootstrapCol(
                            sizes: 'col-12 col-md-3',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                enableInteractiveSelection: !Biblioteca.isDesktop(),
                                readOnly: CompraPedidoCabecalhoPage.descontoNosItems,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.end,
                                controller: _taxaDescontoController,
                                decoration: getInputDecoration(
                                  '',
                                  'Taxa Desconto',
                                  false,
                                  cor: CompraPedidoCabecalhoPage.descontoNosItems ? Colors.amber.shade100 : null,
                                  ),
                                onSaved: (String value) {
                                },
                                onChanged: (text) {
                                  if (_taxaDescontoController.numberValue >= 100) {
                                    _taxaDescontoController.updateValue(99.9);
                                  }
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(taxaDesconto: _taxaDescontoController.numberValue);
                                  paginaMestreDetalheFoiAlterada = true;
                                  _atualizarTotais();
                                },
                              ),
                            ),
                          ),
                          BootstrapCol(
                            sizes: 'col-12 col-md-3',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                enableInteractiveSelection: !Biblioteca.isDesktop(),
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                textAlign: TextAlign.end,
                                controller: _valorDescontoController,
                                decoration: getInputDecoration(
                                  '',
                                  'Valor Desconto',
                                  false,
                                  cor: ViewUtilLib.getTextFieldReadOnlyColor()),
                                onSaved: (String value) {
                                },
                                onChanged: (text) {
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(valorDesconto: _valorDescontoController.numberValue);
                                  paginaMestreDetalheFoiAlterada = true;
                                },
                              ),
                            ),
                          ),
                          BootstrapCol(
                            sizes: 'col-12 col-md-3',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                enableInteractiveSelection: !Biblioteca.isDesktop(),
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                textAlign: TextAlign.end,
                                controller: _valorTotalController,
                                decoration: getInputDecoration(
                                  '',
                                  'Valor Total',
                                  false,
                                  cor: ViewUtilLib.getTextFieldReadOnlyColor()),
                                onSaved: (String value) {
                                },
                                onChanged: (text) {
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(valorTotal: _valorTotalController.numberValue);
                                  paginaMestreDetalheFoiAlterada = true;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white,),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                maxLength: 50,
                                maxLines: 1,
                                initialValue: CompraPedidoCabecalhoPage.compraPedidoCabecalho?.numeroDocumentoEntrada ?? '',
                                decoration: getInputDecoration(
                                  'Conteúdo para o campo Numero Documento Entrada',
                                  'Numero Documento Entrada',
                                  false),
                                onSaved: (String value) {
                                },
                                onChanged: (text) {
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(numeroDocumentoEntrada: text);
                                  paginaMestreDetalheFoiAlterada = true;
                                },
                              ),
                            ),
                          ),
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                maxLength: 50,
                                maxLines: 1,
                                initialValue: CompraPedidoCabecalhoPage.compraPedidoCabecalho?.contato ?? '',
                                decoration: getInputDecoration(
                                  '',
                                  'Nome do Contato',
                                  false),
                                onSaved: (String value) {
                                },
                                onChanged: (text) {
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(contato: text);
                                  paginaMestreDetalheFoiAlterada = true;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white,),
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 0, left: 10, right: 0),
                        child: Text(
                          "Dados para o Sistema Financeiro - Contas a Pagar", 
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                      ),
                      Divider(
                        indent: 10,
                        endIndent: 10,
                        thickness: 2,
                      ),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                enableInteractiveSelection: !Biblioteca.isDesktop(),
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                maxLines: 1,
                                initialValue: CompraPedidoCabecalhoPage.compraPedidoCabecalho?.quantidadeParcelas?.toString() ?? '',
                                decoration: getInputDecoration(
                                  '',
                                  'Quantidade de Parcelas',
                                  false,),
                                onSaved: (String value) {
                                },
                                onChanged: (text) {
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(quantidadeParcelas: int.tryParse(text));
                                  paginaMestreDetalheFoiAlterada = true;
                                },
                              ),
                            ),
                          ),
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                                maxLines: 1,
                                controller: _intervaloEntreParcelasController,
                                decoration: getInputDecoration(
                                  '',
                                  'Intervalo entre Parcelas',
                                  false),
                                onSaved: (String value) {
                                },
                                onChanged: (text) {
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(intervaloEntreParcelas: int.tryParse(text));
                                  paginaMestreDetalheFoiAlterada = true;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white,),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                           BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: InputDecorator(
                                decoration: getInputDecoration(
                                  'Conteúdo para o campo Dia Primeiro Vencimento',
                                  'Dia Primeiro Vencimento',
                                  true),
                                isEmpty: CompraPedidoCabecalhoPage.compraPedidoCabecalho.diaPrimeiroVencimento == null,
                                child: DatePickerItem(
                                  mascara: 'dd/MM/yyyy',
                                  dateTime: CompraPedidoCabecalhoPage.compraPedidoCabecalho.diaPrimeiroVencimento,
                                  firstDate: DateTime.parse('1900-01-01'),
                                  lastDate: DateTime.parse('2050-01-01'),
                                  onChanged: (DateTime value) {
                                    paginaMestreDetalheFoiAlterada = true;
                                    setState(() {
                                      CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(diaPrimeiroVencimento: value);
                                      paginaMestreDetalheFoiAlterada = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          BootstrapCol(
                            sizes: 'col-12 col-md-6',
                            child: Padding(
                              padding: Biblioteca.distanciaEntreColunasQuebraLinha(context),
                              child: TextFormField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                controller: _diaFixoParcelaController,
                                decoration: getInputDecoration(
                                  'Permite informar um dia fixo para as parcelas que serão geradas no Contas a Pagar.',
                                  'Dia Fixo da Parcela',
                                  true,
                                  paddingVertical: 15,
                                  ),
                                onSaved: (String value) {
                                },
                                // validator: ValidaCampoFormulario.validarDIA,
                                onChanged: (text) {
                                  CompraPedidoCabecalhoPage.compraPedidoCabecalho = CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(diaFixoParcela: text);
                                  paginaMestreDetalheFoiAlterada = true;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white,),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12',
                            child: 
                              Text(
                                '* indica que o campo é obrigatório',
                                style: Theme.of(context).textTheme.caption,
                              ),								
                          ),
                        ],
                      ),
                      Divider(color: Colors.white,),
                    ],        
                  ),
                ),
              ),			  
            ),
          ),
        ),
      ),
    );
  }

  void _filtrarColaboradorLookup(String campo, String valor) async {
    final listaFiltrada = await Sessao.db.colaboradorDao.consultarListaFiltro(campo, valor);
    Sessao.retornoJsonLookup = jsonEncode(listaFiltrada);
  }

  void _filtrarFornecedorLookup(String campo, String valor) async {
    final listaFiltrada = await Sessao.db.fornecedorDao.consultarListaFiltro(campo, valor);
    Sessao.retornoJsonLookup = jsonEncode(listaFiltrada);
  }

   _atualizarTotais() {
    double desconto = Biblioteca.calcularDesconto(
      CompraPedidoCabecalhoPage.compraPedidoCabecalho.valorSubtotal, 
      CompraPedidoCabecalhoPage.compraPedidoCabecalho.taxaDesconto
      );
     setState(() {
      CompraPedidoCabecalhoPage.compraPedidoCabecalho = 
        CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(
          valorDesconto: desconto,
          valorTotal: CompraPedidoCabecalhoPage.compraPedidoCabecalho.valorSubtotal - desconto,
        );
     });
  }

  void _verificarDescontoNosItens() {
    double totalDescontosItens = 0;
    for (CompraDetalhe compraDetalhe in CompraPedidoCabecalhoPage.listaCompraDetalhe) {
      totalDescontosItens = totalDescontosItens + (compraDetalhe.compraPedidoDetalhe.valorDesconto ?? 0);
    } 
    setState(() {
      CompraPedidoCabecalhoPage.descontoNosItems = (totalDescontosItens > 0);
    });
  }

  Future _gerarFinanceiro() async {
    if (_podeRealizarIntegracao()) {
      bool podeGerar = true;
      if (CompraPedidoCabecalhoPage.compraPedidoCabecalho.geraFinanceiro == 'S') {
        gerarDialogBoxInformacao(context, 'Os dados para o sistema financeiro já foram gerados.');
      } else {
        gerarDialogBoxConfirmacao(context, 'Deseja gerar os dados para o Sistema Financeiro - Contas a Pagar?', () async {
          // Navigator.of(context).pop();
          if (CompraPedidoCabecalhoPage.compraPedidoCabecalho.quantidadeParcelas == null || CompraPedidoCabecalhoPage.compraPedidoCabecalho.quantidadeParcelas <= 0) {
            showInSnackBar("Por favor, informe a quantidade de parcelas.", context);          
            podeGerar = false;
          }
          if (CompraPedidoCabecalhoPage.compraPedidoCabecalho.diaPrimeiroVencimento == null) {
            showInSnackBar("Por favor, informe o primeiro dia do vencimento.", context);          
            podeGerar = false;
          }
          if (CompraPedidoCabecalhoPage.compraPedidoCabecalho.intervaloEntreParcelas == null && CompraPedidoCabecalhoPage.compraPedidoCabecalho.diaFixoParcela == null) {
            showInSnackBar("Por favor, informe o intervalo entre as pacelas OU o dia fixo.", context);          
            podeGerar = false;
          }
          // gera as parcelas
          if (podeGerar) {
            // define o primeiroVencimento
            DateTime primeiroVencimento = CompraPedidoCabecalhoPage.compraPedidoCabecalho.diaPrimeiroVencimento;
            final diaFixoParcela = CompraPedidoCabecalhoPage.compraPedidoCabecalho.diaFixoParcela;
            final quantidadeParcelas = CompraPedidoCabecalhoPage.compraPedidoCabecalho.quantidadeParcelas;
            final intervaloEntreParcelas = CompraPedidoCabecalhoPage.compraPedidoCabecalho.intervaloEntreParcelas;
            // se tiver dia fixo, calcula as parcelas levando em conta apenas o mes
            if (diaFixoParcela != null && diaFixoParcela != '') {
              primeiroVencimento = DateTime.utc(primeiroVencimento.year, primeiroVencimento.month, int.parse(diaFixoParcela));        
            } 

            // gera as parcelas de acordo com critérios informados
            num somaParcelas = 0;
            num residuo = 0;
            List<ContasPagar> listaContasPagar = [];
            for (var i = 0; i < quantidadeParcelas; i++) {
              final parcelaPagar = 
                ContasPagar(
                  id: null,
                  idCompraPedidoCabecalho: CompraPedidoCabecalhoPage.compraPedidoCabecalho.id,
                  idFornecedor: CompraPedidoCabecalhoPage.compraPedidoCabecalho.idFornecedor,
                  dataLancamento: DateTime.now(),
                  dataVencimento: (diaFixoParcela != null && diaFixoParcela != '') 
                                  ? DateTime.utc(primeiroVencimento.year, primeiroVencimento.month + i, primeiroVencimento.day)
                                  : primeiroVencimento.add(new Duration(days: intervaloEntreParcelas * i)),
                  valorAPagar: num.parse((CompraPedidoCabecalhoPage.compraPedidoCabecalho.valorTotal / quantidadeParcelas).toStringAsFixed(Constantes.decimaisValor)),
                  statusPagamento: 'A',
                  historico: 'Gerado pelo módulo compras. Parcela ' + (i+1).toString() + ' de ' + quantidadeParcelas.toString(),
                );
              listaContasPagar.add(parcelaPagar);
              somaParcelas = somaParcelas + parcelaPagar.valorAPagar;
            }
            // verifica se sobraram centavos no cálculo e lança na primeira parcela
            residuo = CompraPedidoCabecalhoPage.compraPedidoCabecalho.valorTotal - somaParcelas;
            if (residuo != 0) {
              var primeiraParcela = listaContasPagar[0];
              primeiraParcela = primeiraParcela.copyWith(
                valorAPagar: primeiraParcela.valorAPagar + residuo,
              );
            } 

            final inseriuParcelas = await Sessao.db.contasPagarDao.inserirParcelas(listaContasPagar);
            if (inseriuParcelas) {
              CompraPedidoCabecalhoPage.compraPedidoCabecalho = 
                CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(
                  geraFinanceiro: 'S'
                );
              await Sessao.db.compraPedidoCabecalhoDao.atualizarCabecalho(CompraPedidoCabecalhoPage.compraPedidoCabecalho);
              showInSnackBar("Dados financeiros gerados com sucesso no Contas a Pagar.", context, corFundo: Colors.blue.shade900);
            }
          }
        });
      }
    }
  }

  Future _atualizarEstoque() async {
    if (_podeRealizarIntegracao()) {
      if (CompraPedidoCabecalhoPage.compraPedidoCabecalho.atualizouEstoque == 'S') {
        gerarDialogBoxInformacao(context, 'O estoque já foi atualizado com os dados desse pedido.');
      } else {
        gerarDialogBoxConfirmacao(context, 'Deseja atualizar o estoque? O pedido não poderá mais ser alterado após essa ação.', () async {
          // Navigator.of(context).pop();
            CompraPedidoCabecalhoPage.compraPedidoCabecalho = 
              CompraPedidoCabecalhoPage.compraPedidoCabecalho.copyWith(
                atualizouEstoque: 'S'
              );
            await Sessao.db.compraPedidoCabecalhoDao.alterar(
              CompraPedidoCabecalhoPage.compraPedidoCabecalho, 
              CompraPedidoCabecalhoPage.listaCompraDetalhe,
              atualizaEstoque: true,
            );
            showInSnackBar("Estoque atualizado com sucesso.", context, corFundo: Colors.blue.shade900);          
        });
      }
    }
  }

  bool _podeRealizarIntegracao() {
    bool retorno = true;
    if (CompraPedidoCabecalhoPage.compraPedidoCabecalho.id == null) {
      retorno = false;
      gerarDialogBoxInformacao(context, 'É necessário salvar o pedido antes de realizar essa operação.');
    } else if (CompraPedidoCabecalhoPage.listaCompraDetalhe.length == 0) {
      retorno = false;
      gerarDialogBoxInformacao(context, 'Não existem itens no pedido.');
    } 
    return retorno;
  }

}