#region Default Assemblies
using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using Fs.Data.SqlClient;
using System.Drawing;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using AjaxControlToolkit;

#endregion

#region External Assemblies Fs
using Fs.Common;
using Fs.Enumeration;
using Fs.Services.Util;
using Fs.Business.Sinistro;
using Fs.Business.Sies;
using Fs.Security.Business;
#endregion

#region Exeternal Assemblies FrameWork
using System.Configuration;
#endregion

namespace WebAppSinistro
{
    /// <summary>
    /// Summary description for Indenizacao.
    /// </summary>
    public partial class JuridicoIndenizaDespesa : Fs.Web.UI.SimplePage
    {
        #region Private Enumeration
        private enum LiquidacaoEnum : short
        {
            Total,
            Parcial
        }
        private enum TabFooterIndenixEnum : int
        {
            Liberar = 1
        }
        #endregion

        #region Protected Level Objects
        protected System.Web.UI.WebControls.Panel PObservacao;

        #endregion

        #region Consistent, Clean Objects and ChangeState
        Consistent oConsistent = new Consistent();
        ChangeState oCSIndenizacao = new ChangeState();
        ChangeState oCSParcela = new ChangeState();
        ChangeState oCSObservacao = new ChangeState();
        ChangeState oCSFaturamento = new ChangeState();
        Clean oClean = new Clean();
        #endregion

        #region Private Variables
        string answer = string.Empty;
        string idget = string.Empty;
        #endregion

        #region Protected Level Objects
        protected Fs.Web.UI.WebControls.TextBox dttxtLiberacao;
        protected Fs.Web.UI.WebControls.TextBox dttxtPagamento;

        #endregion

        #region Local Method
        private short Situacao(string nomesituacao)
        {
            short codsitua;
            if (nomesituacao == "Pendente")
                codsitua = 0;
            else if (nomesituacao == "Liberado")
                codsitua = 1;
            else if (nomesituacao == "Pago")
                codsitua = 2;
            else
                codsitua = 5;

            return codsitua;
        }
        #endregion

        #region PageLoad

        protected void Page_Load(object sender, System.EventArgs e)
        {
            #region Controle de Sessão e de Pedido Regular
            if (Session["ALLACCESS"] == null || this.PedidoRegular == false)
            {
                //Sessão Encerrada
                try
                {
                    //Devido aos frames, não podemos simplesmente fazer um Redirect
                    string script = "<script>";
                    if (Session["ALLACCESS"] == null)
                        script += "javascript:window.open('inicial.aspx?proc=new&atend=n&msg=fimsessao','_top')";
                    else
                        script += "javascript:window.open('inicial.aspx?proc=new&atend=n&msg=pedidoirregular','_top')";
                    script += "</script>";
                    //  O Script deve ser enviado na página, não adianta utilizar
                    //	Métodos de registro de Script pois a thread será abortada
                    Response.Write(script);
                    script = null;
                    //Aborta a thread, impedindo o proceguimento do processamento
                    //	Este comando dispara uma excessão.
                    Response.End();

                }
                catch { Server.ClearError(); }
            }

            #endregion

            #region Controle de Alçadas
            if (!Access.ValidateAccess((DataSet)Session["ALLACCESS"], "JudIndeniza.aspx"))
            {
                Url.NavigateUrl(this, "inicial.aspx?proc=new&atend=n", "_top", 0, 0);
                return;
            }

            Access.CurrentPage = this;
            Consistent.CurrentPage = this;
            Access.AllAccess = (DataSet)Session["ALLACCESS"];
            Access.Module = "WF010";
            Access.Program = "JudIndeniza.aspx";
            Access.GrantAccessMenuAlfaSegNet(TabBase1);
            #endregion

            #region Inicialização de Controles
            TabBase1.BotaoExcluirEnabled = false;
            TabBase1.BotaoImprimirEnabled = false;
            TabBase1.BotaoAjudaEnabled = false;
            TabBase1.BotaoImprimirEnabled = false;

            if (Session["LOG_CDAUX"] != null)
            {
                TabBase1.BotaoNovoEnabled = false;
                TabBase1.BotaoRecuperarEnabled = false;
                TabBase1.BotaoPesquisarEnabled = false;
            }

            #endregion

            try
            {
                if (!IsPostBack)
                {
                    if (!string.IsNullOrEmpty(Request.QueryString["cdaviso"]))
                        txtProtocolo.Text = (string)Request.QueryString["cdaviso"];

                    if (!string.IsNullOrEmpty(Request.QueryString["cddirec"]))
                        txtSequencia.Text = (string)Request.QueryString["cddirec"];

                    if (!string.IsNullOrEmpty(Request.QueryString["cdindeniz"]))
                        txtIndenizacao.Text = (string)Request.QueryString["cdindeniz"];

                    string StrUrl = HttpContext.Current.Request.Url.ToString();

                    mpeDevolver.Hide();

                    #region Identifica Retorno por ANSWER
                    if (!string.IsNullOrEmpty(Request.QueryString["proc"]))
                    {
                        if (Request.QueryString["proc"] == "new")
                            this.Kill();
                    }

                    answer = Request.QueryString["answer"];

                    if (!string.IsNullOrEmpty(Request.QueryString["answer"]))
                    {
                        if (!string.IsNullOrEmpty(Request.QueryString["indenizlib"]))
                        {
                            idget = Request.QueryString["indenizlib"];
                            ArrayList arrKey = (ArrayList)Session["IND_LIB_KEY"];

                            txtProtocolo.Text = arrKey[0].ToString();

                            txtIndenizacao.Text = arrKey[1].ToString();

                            arrKey = null;

                            Session.Remove("IND_LIB_KEY");

                            this.LoadDllCombo();

                            AlfaSegNET.Web.UI.WebControls.ToolBar.ToolBarItem itemTB = new AlfaSegNET.Web.UI.WebControls.ToolBar.ToolBarItem();
                            itemTB.ItemTag = "Recuperar";

                            TabBase1_ItemClick(itemTB);

                            if (Request.QueryString["answer"].ToLower() == "ok")
                            {
                                hdfTabFooterSelectedIndex.Value = Convert.ToInt32(TabFooterIndenixEnum.Liberar).ToString();
                                this.TabFooterIndenizacao_SelectedIndexChange(null, null);
                            }
                            else
                                TabBase1_ItemClick(itemTB);
                        }
                        else if (!string.IsNullOrEmpty(Request.QueryString["operation"]))
                        {
                            if (Request.QueryString["operation"] == "excluir")
                            {
                                if (Request.QueryString["answer"].ToLower() == "ok")
                                {
                                    this.ReloadPageState();

                                    AlfaSegNET.Web.UI.WebControls.ToolBar.ToolBarItem itemTB =
                                    new AlfaSegNET.Web.UI.WebControls.ToolBar.ToolBarItem();
                                    itemTB.ItemTag = "Excluir";

                                    TabBase1_ItemClick(itemTB);
                                }
                            }
                        }
                    }
                    #endregion

                    LoadDllCombo();

                    //if (!string.IsNullOrEmpty(txtProtocolo.Text) && !string.IsNullOrEmpty(txtSequencia.Text))
                    //    RecuperaPrimeiraIndenizacao();
                }

                #region Configuração de Painel

                PanelFooter1.Style.Add("TOP", "815px");
                #endregion

                #region Consistência e Limpeza
                // set not null fields						 			
                oConsistent.Add(txtProtocolo);
                oConsistent.Add(ddlReferencia);
                oConsistent.Add(ddlOperacao);
                oConsistent.Add(ddlMeioPagto);
                //oConsistent.Add(txtItem);
                oConsistent.Add(txtBeneficiario);
                oConsistent.Add(rblLiquidacao);
                oConsistent.Add(ddlCobertura);
                oConsistent.Add(vltxtValorMaximo);
                oConsistent.Add(vltxtIndenizacao);
                oConsistent.Add(vltxtPago);

                //prepare to clear objects
                oClean.Add(txtProtocolo);
                oClean.Add(txtIndenizacao);
                oClean.Add(ddlOperacao);
                oClean.Add(ddlMeioPagto);
                //oClean.Add(txtItem);
                oClean.Add(txtBeneficiario);
                oClean.Add(txtLiberacao);
                oClean.Add(ddlCobertura);
                oClean.Add(txtEntregaDoc);
                oClean.Add(txtObservacao);
                oClean.Add(vltxtValorMaximo);
                oClean.Add(vltxtIndenizacao);
                oClean.Add(vltxtPago);
                oClean.Add(dttxtDataVencto);
                oClean.Add(nutxtBanco);
                oClean.Add(txtContaCorrente);
                oClean.Add(nutxtAgencia);
                oClean.Add(txtDigitoAg);
                oClean.Add(txtDigitoCC);
                oClean.Add(txtNroNF);
                oClean.Add(nuNrCodBarras1);
                oClean.Add(nuNrCodBarras2);
                oClean.Add(nuNrCodBarras3);
                oClean.Add(nuNrCodBarras4);
                oClean.Add(nuNrCodBarras5);
                oClean.Add(nuNrCodBarras6);
                oClean.Add(nuNrCodBarras7);
                oClean.Add(nuNrCodBarras8);
                oClean.Add(txtObsCheque);

                oClean.Add(chkNaoIncluirAtualizacaoMonetaria);
                oClean.Add(chkNaoIncluirCustasJudiciais);
                oClean.Add(chkNaoIncluirHonorarioContratual);
                oClean.Add(chkNaoIncluirHonorariosAdvocaticios);
                oClean.Add(chkNaoIncluirHonorarioSucumbencia);
                oClean.Add(chkNaoIncluirJurosDeMora);
                oClean.Add(chkNaoIncluirMulta);
                oClean.Add(chkNaoIncluirReservaDefesaSegurado);
                oClean.Add(chkNaoIncluirVariacaoCambial);
                oClean.Add(vlAtualizacaoMonetariaPago);
                oClean.Add(vlCustasJudiciaisPago);
                oClean.Add(vlHonorarioContratualPago);
                oClean.Add(vlHonorariosAdvocaticiosPago);
                oClean.Add(vlHonorarioSucumbenciaPago);
                oClean.Add(vlJurosDeMoraPago);
                oClean.Add(vlMultaPago);
                oClean.Add(vlReservaDefesaSeguradoPago);

                //Set on/off change state properties - Indenização
                oCSIndenizacao.Add(txtProtocolo);
                oCSIndenizacao.Add(txtIndenizacao);
                oCSIndenizacao.Add(ddlCobertura);
                oCSIndenizacao.Add(txtBeneficiario);
                oCSIndenizacao.Add(ddlOperacao);
                oCSIndenizacao.Add(ddlMeioPagto);
                oCSIndenizacao.Add(nutxtBanco);
                oCSIndenizacao.Add(nutxtAgencia);
                oCSIndenizacao.Add(txtDigitoAg);
                oCSIndenizacao.Add(txtContaCorrente);
                oCSIndenizacao.Add(txtDigitoCC);
                oCSIndenizacao.Add(vltxtIndenizacao);
                oCSIndenizacao.Add(dttxtDataVencto);
                oCSIndenizacao.Add(ddlReferencia);
                oCSIndenizacao.Add(rblLiquidacao);

                //Set on/off change state properties - Observação
                oCSObservacao.Add(txtObservacao);
                oCSObservacao.Add(txtEntregaDoc);

                //Set on/off change state properties - Faturamento
                oCSFaturamento.Add(txtNroNF);
                oCSFaturamento.Add(txtSerieNF);
                oCSFaturamento.Add(txtValorNF);
                oCSFaturamento.Add(btnNotaFiscal);

                //special release word
                oClean.Add(txtSituacao);
                #endregion

                if (!Page.IsPostBack)
                {
                    #region Liberação de pagamento de Oficinas

                    lblUsuario.Text = "";
                    lblData.Text = "";
                    dvAnalise.Visible = false;

                    //Liberação de pagamento de Oficinas
                    if (!string.IsNullOrEmpty(Request.QueryString["cdaviso"]))
                    {
                        Session["ICDAVISO"] = txtProtocolo.Text.Trim();
                        Session["IDPESSOA"] = Request.QueryString["cdpester"];

                        if (!string.IsNullOrEmpty(Request.QueryString["arqoficina"]))
                        {
                            Session["arqoficina"] = Request.QueryString["arqoficina"].ToString();

                            if (Request.QueryString["cdusuarioAnalise"] != null)
                            {
                                string cdusuarioAnalise = Request.QueryString["cdusuarioAnalise"].ToString();
                                string dtAddAnalise = Request.QueryString["dtAddAnalise"].ToString();

                                dvAnalise.Visible = false;

                                if (string.IsNullOrEmpty(cdusuarioAnalise).Equals(false))
                                {
                                    lblUsuario.Text = cdusuarioAnalise.Trim();
                                    lblData.Text = dtAddAnalise;
                                    dvAnalise.Visible = true;
                                }
                            }
                            this.Recuperar();
                        }
                    }

                    #endregion

                    if (Session["INDENIZACAO_LIMPA"] == null)
                        this.ReloadPageState();
                    else
                        this.ddlMeioPagto_SelectedIndexChanged(null, null);

                    Session.Remove("INDENIZACAO_LIMPA");

                    if (!string.IsNullOrEmpty(txtProtocolo.Text) && !string.IsNullOrEmpty(txtSequencia.Text))
                        RecProtocolo();

                    if (Session["INDENIZACAOCOB"] != null)
                    {
                        ddlCobertura.SelectedIndex = Convert.ToInt32(Session["INDENIZACAOCOB"]);
                        Session.Remove("INDENIZACAOCOB");
                    }

                    txtSolicitacao.Text = Transformer.CheckValue(Convert.ToDateTime(Session["DATASISTEMA"]));

                    IndenizacaoSinistro oIS = new IndenizacaoSinistro();

                    if (Request.QueryString.Count > 0)
                    {
                        //Update
                        if (!string.IsNullOrEmpty(Request.QueryString["answer"]))
                        {
                            if (Session["INDENIZACAO"] == null)
                                Session["INDENIZACAO"] = Session["INDENIZACAOANSWER"];

                            answer = Request.QueryString["answer"];

                            if (answer.ToLower() != "cancel" && Request.QueryString["operation"] == null)
                            {
                                int tabIndex = int.Parse(Request.QueryString["tabindex"]);

                                AlfaSegNET.Web.UI.WebControls.ToolBar.ToolBarItem itemTB = new AlfaSegNET.Web.UI.WebControls.ToolBar.ToolBarItem();
                                itemTB.ItemTag = "Recuperar";

                                this.TabBase1_ItemClick(itemTB);
                            }
                        }

                        //Parameters ContaCorrente (ContaPessoa)
                        if (Request.QueryString["idpes"] != null && Request.QueryString["nrseqcta"] != null &&
                            Request.QueryString["cdbco"] != null && Request.QueryString["cdagn"] != null &&
                            Request.QueryString["nrctaccr"] != null)
                        {
                            nutxtBanco.Text = Request.QueryString["cdbco"].ToString();
                            nutxtAgencia.Text = Request.QueryString["cdagn"].ToString();
                            txtDigitoAg.Text = Request.QueryString["dgtagn"].ToString();
                            txtContaCorrente.Text = Request.QueryString["nrctaccr"].ToString();
                            txtDigitoCC.Text = Request.QueryString["dgtctaccr"].ToString();
                        }

                        if (Request.QueryString["numnotafiscal"] != null && Request.QueryString["serienotafiscal"] != null && Request.QueryString["valornotafiscal"] != null)
                        {
                            this.txtNroNF.Text = Request.QueryString["numnotafiscal"].Trim();
                            this.txtSerieNF.Text = Request.QueryString["serienotafiscal"].Trim();
                            this.txtValorNF.Text = Request.QueryString["valornotafiscal"].Trim();
                        }

                        //Check seek Indenizacao
                        //if (!string.IsNullOrEmpty(Request.QueryString["cdaviso"]))
                        //{
                        //    if (Request.QueryString["cdaviso"] != "0" && Request.QueryString["getpage"] == null)
                        //        RecParametros(true);
                        //}


                        if (!string.IsNullOrEmpty(Request.QueryString["idpes"]) && !string.IsNullOrEmpty(Request.QueryString["nmpes"]))
                        {
                            txtBeneficiario.Text = Request.QueryString["nmpes"].ToString();
                            Session["IDPESSOA"] = Request.QueryString["idpes"];
                            Session["CGCCPFPESSOA"] = Request.QueryString["cgccpf"];
                            this.PopulaTipoServico();
                            this.PopulaCC();

                        }

                        //Vindo da página de Pagamentos Solicitados
                        if (!string.IsNullOrEmpty(Request.QueryString["vlsolpag"]) && !string.IsNullOrEmpty(Request.QueryString["cdsolpag"]))
                        {
                            this.vltxtIndenizacao.Text = Request.QueryString["vlsolpag"];
                            this.dttxtDataVencto.Text = Request.QueryString["dtvenc"];
                            this.txtcdsolpag.Text = Request.QueryString["cdsolpag"];
                            this.RecuperarSolObs(int.Parse(Request.QueryString["cdaviso"]), short.Parse(Request.QueryString["cdsolpag"]));
                            Session["arqoficina"] = null;
                        }

                        if (!string.IsNullOrEmpty(Request.QueryString["operation"]))
                        {
                            if (Request.QueryString["operation"] == "excluir")
                                TabBase1.Itens[Convert.ToInt32(TabBaseEnum.Excluir)].Enabled = true;
                        }

                        if (!string.IsNullOrEmpty(txtProtocolo.Text) && !string.IsNullOrEmpty(txtSequencia.Text) && !string.IsNullOrEmpty(txtIndenizacao.Text))
                            this.Recuperar();
                        else if (!string.IsNullOrEmpty(txtProtocolo.Text) && !string.IsNullOrEmpty(txtSequencia.Text))
                            this.HabilitarDespesasJudicial();
                    }

        #endregion

                    #region Popula Combo de Acesso Rápido
                    string pcdconseg, pcdemi;

                    if (Session["PCDCONSEG"] != null) pcdconseg = Session["PCDCONSEG"].ToString();
                    else pcdconseg = "";

                    if (Session["PCDEMI"] != null) pcdemi = Session["PCDEMI"].ToString();
                    else pcdemi = "";

                    Util.MontarDDLAcessoRapido(ref this.QuickAccess1, (DataSet)Session["ALLACCESS"], "Jurídico", this.txtProtocolo.Text, pcdconseg, pcdemi, (Session["TP"] == null || Session["TP"].ToString() == "0"));
                    this.QuickAccess1.SelectedIndex = 0;

                    if (txtSituacao.Text == "Pendente")
                    {
                        if (ddlAnexos.Items.Count > 0)
                            PModalDevolver.Visible = true;
                    }

                    #endregion
                }

                this.GerenciarStatus();

                if (Session["LOG_CDAUX"] != null)
                    Util.DesabilitaControles(this.Controls);

                if (!IsPostBack)
                    this.ddlMeioPagto_SelectedIndexChanged(null, null);

                nuNrCodBarras1.Attributes.Add("onkeyup", "focusCodBarras(this)");
                nuNrCodBarras2.Attributes.Add("onkeyup", "focusCodBarras(this)");
                nuNrCodBarras3.Attributes.Add("onkeyup", "focusCodBarras(this)");
                nuNrCodBarras4.Attributes.Add("onkeyup", "focusCodBarras(this)");
                nuNrCodBarras5.Attributes.Add("onkeyup", "focusCodBarras(this)");
                nuNrCodBarras6.Attributes.Add("onkeyup", "focusCodBarras(this)");
                nuNrCodBarras7.Attributes.Add("onkeyup", "focusCodBarras(this)");
                nuNrCodBarras8.Attributes.Add("onkeyup", "focusCodBarras(this)");
            }
            catch (Exception error)
            {
                MessageService.Alert("Operação não Efetuada ! Contate Sistemas.", this);
            }
        }

        //private void RecuperaPrimeiraIndenizacao()
        //{
        //    Fs.Data.Sinistro.IndenizacaoSinistro oIS = new Fs.Data.Sinistro.IndenizacaoSinistro();
        //    oIS.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
        //    oIS.cddirec = short.Parse(txtSequencia.Text.Trim());

        //    int cdindeniz = 0;

        //    cdindeniz = oIS.recIndenizacaoSinistroJudicialPrimeiro();

        //    if (cdindeniz != 0)
        //    {
        //        txtIndenizacao.Text = cdindeniz.ToString();
        //        Recuperar();
        //    }
        //}

        #region Web Form Designer generated code
        override protected void OnInit(EventArgs e)
        {
            //
            // CODEGEN: This call is required by the ASP.NET Web Form Designer.
            //
            InitializeComponent();
            base.OnInit(e);
        }

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.TabBase1.ItemClick += new AlfaSegNET.Web.UI.WebControls.ToolBar.ItemEventHandler(TabBase1_ItemClick);
            this.TabJuridico.TabClick += new Telerik.Web.UI.RadTabStripEventHandler(TabJuridico_SelectedIndexChange);
        }
        #endregion

        protected void TabJuridico_SelectedIndexChange(object sender, System.EventArgs e)
        {
            Telerik.Web.UI.RadTabStrip tabEvento = (Telerik.Web.UI.RadTabStrip)sender;

            System.Text.StringBuilder url = new System.Text.StringBuilder();
            string cdaviso = txtProtocolo.Text.Trim();
            string cdpester = Request.QueryString["cdpester"];
            string tpter = Request.QueryString["tpter"];
            string cddirec = txtSequencia.Text.Trim();
            string tpacao = Request.QueryString["tpacao"];
            string vlestima = Request.QueryString["vlestima"];

            switch (tabEvento.SelectedIndex)
            {
                case 0:
                    url.Append("JuridicoBase.aspx");

                    break;
                case 1:
                    url.Append("JuridicoTextos.aspx");

                    break;
                case 2:
                    url.Append("JuridicoIndenizaDespesa.aspx");

                    break;
                case 3:
                    url.Append("JuridicoDepositoJuizo.aspx");

                    break;
                case 4:
                    url.Append("JuridicoBloqueioJudicial.aspx");

                    break;
            }

            url.Append("?cdaviso=" + cdaviso);
            url.Append("&cdparte=1");
            url.Append("&cdpester=" + cdpester);
            url.Append("&tpter=" + tpter);
            url.Append("&cddirec=" + cddirec);
            url.Append("&nrseqcom=0");
            url.Append("&tpacao=" + tpacao);
            url.Append("&vlestima=" + vlestima);

            Session.Remove("INDENIZACAO_LIMPA");
            Session.Remove("INDENIZACAO_SAVE");

            Response.Redirect(url.ToString());
        }

        #region Arquivos

        /// <summary>
        /// Recupera as imagens anexadas
        /// </summary>
        private void RecuperarImagem()
        {
            Fs.Data.Sinistro.ArquivoAnexoSinistro oAAS = new Fs.Data.Sinistro.ArquivoAnexoSinistro();

            oAAS.cod_aviso = int.Parse(this.txtProtocolo.Text);

            Fs.Data.Sies.Pessoa oPES = new Fs.Data.Sies.Pessoa();
            Fs.Data.Sinistro.AvisoSinistro oAVS = new Fs.Data.Sinistro.AvisoSinistro();
            Fs.Data.Sinistro.Orcamento Orc = new Fs.Data.Sinistro.Orcamento();

            oAVS.cod_aviso = int.Parse(this.txtProtocolo.Text);
            oAVS.recAvisoSinistro();
            Orc.cod_aviso = oAVS.cod_aviso;
            DataSet ds = Orc.recOrcamentoAviso();
            int cdpester = 0;

            oPES.cod_pessoa = oAVS.cod_pessoa;
            oPES.recPessoa();
            if (ds != null)
            {
                if (ds.Tables.Count > 0)
                {
                    if (ds.Tables[0].Rows.Count > 0)
                    {
                        cdpester = int.Parse(ds.Tables[0].Rows[ds.Tables[0].Rows.Count - 1]["cdpester"].ToString());
                    }
                }
            }

            oAAS.cod_pes_ter = cdpester;
            //cdpester 
            // oAAS.cod_pes_ter = 98901;

            // oAAS.Imports = 1;
            // DataSet dsArq = oAAS.recTodosArquivoAnexoSinistro();
            DataSet dsArq = oAAS.recArquivoAnexoSinistroOficina(0, 1);

            this.ddlAnexos.Items.Clear();


            Session["AvisoAnexarArquivoOficina"] = dsArq;



            //  this.txtSegurado.Text = oPES.nome_pessoa;
            Session["AvisoAnexarArquivo"] = oAAS.cod_aviso;
            if (oAAS.RecordCount == 0) return;


            if (dsArq != null)
            {
                if (dsArq.Tables.Count > 0)
                {
                    if (dsArq.Tables[0].Rows.Count > 0)
                    {
                        this.ddlAnexos.DataSource = dsArq;
                        this.ddlAnexos.DataBind();

                        CarregarGridArq();
                    }
                }
            }


        }

        #region Eventos Grid

        protected void gvArq_RowEditing(object sender, GridViewEditEventArgs e)
        {
            int index = e.NewEditIndex;
            int IDRegistro = int.Parse(gvArq.DataKeys[index].Value.ToString());
            this.AbrirArquivo(IDRegistro);

            GridViewRow row = gvArq.Rows[index];

        }

        protected void gvArq_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.DataRow)
            {
                CheckBox chkDevolucao = (CheckBox)e.Row.FindControl("chkDevolucao");
                string valor = DataBinder.Eval(e.Row.DataItem, "fldevolucao").ToString();
                chkDevolucao.Checked = bool.Parse(string.IsNullOrEmpty(valor).Equals(true) ? "false" : valor);

                Label lblcdarq = (Label)e.Row.FindControl("lblcdarq");
                lblcdarq.Text = DataBinder.Eval(e.Row.DataItem, "cdarq").ToString();
                lblcdarq.Visible = false;
                e.Row.FindControl("lblcdarq").Visible = false;

                Label lblcdTpDocumento = (Label)e.Row.FindControl("lblcdTpDocumento");
                lblcdTpDocumento.Text = DataBinder.Eval(e.Row.DataItem, "cdTpDocumento").ToString();
                lblcdTpDocumento.Visible = false;
                e.Row.FindControl("lblcdTpDocumento").Visible = false;

                Label lblTipoArquivo = (Label)e.Row.FindControl("lblTipoArquivo");
                lblTipoArquivo.Text = DataBinder.Eval(e.Row.DataItem, "TipoDocumento").ToString();

                Label lblDataEnvio = (Label)e.Row.FindControl("lblDataEnvio");
                lblDataEnvio.Text = DataBinder.Eval(e.Row.DataItem, "dtenvio").ToString();
            }
        }

        /// <summary>
        /// Carrega os dados no Grid
        /// </summary>
        private void CarregarGridArq()
        {
            DataSet dsArq = new DataSet();

            if (Session["AvisoAnexarArquivoOficina"] != null)
            {
                dsArq = (DataSet)Session["AvisoAnexarArquivoOficina"];
            }

            if (dsArq != null)
            {
                if (dsArq.Tables.Count > 0)
                {
                    if (dsArq.Tables[0].Rows.Count > 0)
                    {
                        gvArq.DataSource = dsArq.Tables[0];
                        gvArq.DataBind();

                        //gvArqNew.DataSource = dsArq.Tables[0];
                        //gvArqNew.DataBind();
                    }
                }
            }

        }


        #endregion



        #region Métodos Auxiliares

        private void AtualizaSessionGridView(GridViewRow row)
        {
            var valor = row.Cells[1].Text;

            bool Desabilitar = bool.Parse(valor);
        }

        /// <summary>
        /// Abre o arquivo selecionado
        /// </summary>
        /// <param name="idRegistro">Identificador de registro</param>
        private void AbrirArquivo(int idRegistro)
        {
            try
            {

                DataSet dsArq = (DataSet)Session["AvisoAnexarArquivoOficina"];

                string contentType = "";
                byte[] arquivo = null;
                string nomearquivo = string.Empty;

                if (dsArq != null)
                {
                    if (dsArq.Tables.Count > 0)
                    {
                        if (dsArq.Tables[0].Rows.Count > 0)
                        {
                            DataView dvArq = dsArq.Tables[0].AsDataView();

                            dvArq.RowFilter = " cdarq=" + idRegistro;

                            foreach (DataRowView drv in dvArq)
                            {


                                // var arq = arquivosSinistro.Find(x => x.IDArq.Equals(idRegistro));


                                contentType = drv["dscontenttype"].ToString(); //arq.dscontenttype;
                                arquivo = (byte[])drv["imgarquivo"]; //arq.imgarquivo;
                                nomearquivo = drv["nmarquivo"].ToString();// arq.nmarquivo;

                                Response.ClearContent();
                                Response.ClearHeaders();
                                Response.Buffer = true;
                                Response.ContentType = contentType.Trim();
                                Response.AddHeader("Content-Length", arquivo.Length.ToString());
                                Response.AddHeader("Content-disposition", "attachment; filename=" + nomearquivo);
                                Response.BufferOutput = true;
                                Response.OutputStream.Write(arquivo, 0, arquivo.Length);
                                Response.Flush();
                            }
                        }

                    }
                }

            }

            catch (Exception error)
            {
                MessageService.Alert("Operação não efetuada. Contate Sistemas!", this);
            }
        }


        #endregion
        protected void ibVerAnexo_Click(object sender, System.Web.UI.ImageClickEventArgs e)
        {
            if (this.ddlAnexos.SelectedValue.Trim().Length == 0)
                return;

            Url.NavigateUrl(this, "ShowDoc.aspx?cdarqimagem=" + this.ddlAnexos.SelectedValue.Trim() + "&cdavisoimagem=" + this.txtProtocolo.Text, "_blank", 0, 0);
        }

        protected void btnSair_Click(object sender, System.EventArgs e)
        {

            txtObsDevolucao.Text = string.Empty;
            chkFaltaArq.Checked = false;

        }

        private void AnalisePagamento()
        {
            try
            {
                if (Session["AvisoAnexarArquivoOficina"] != null)
                {
                    Fs.Data.Sinistro.ArquivoAnexoSinistro oAAS = new Fs.Data.Sinistro.ArquivoAnexoSinistro();
                    oAAS.cod_aviso = int.Parse(this.txtProtocolo.Text);


                    Fs.Data.Sinistro.AvisoSinistro oAVS = new Fs.Data.Sinistro.AvisoSinistro();
                    Fs.Data.Sinistro.Orcamento oRC = new Fs.Data.Sinistro.Orcamento();
                    oAVS.cod_aviso = int.Parse(this.txtProtocolo.Text);
                    oAVS.recAvisoSinistro();

                    Fs.Business.Sinistro.IndenizacaoSinistro IndSis = new Fs.Business.Sinistro.IndenizacaoSinistro();

                    DataSet ds = (DataSet)Session["AvisoAnexarArquivoOficina"];
                    DateTime dtSistema = DateTime.Parse(Session["DATASISTEMA"].ToString());

                    if (ds != null)
                    {
                        if (ds.Tables.Count > 0)
                        {
                            if (ds.Tables[0].Rows.Count > 0)
                            {
                                int cdaviso = int.Parse(ds.Tables[0].Rows[0]["cdaviso"].ToString());
                                int cdpester = int.Parse(ds.Tables[0].Rows[0]["cdpester"].ToString());

                                if (oAVS.AvisoSinistroAnalisePG(cdaviso, cdpester, true, Session["USER"].ToString()).Equals(true))
                                    MessageService.Alert("Indenização colocada em Analise de pagamento com sucesso !", this);
                            }
                        }
                    }
                }
            }
            catch (Exception error)
            {
                MessageService.Alert("Operação não Efetuada ! Contate Sistemas.", this);
            }


        }
        protected void btnDevolver_Click(object sender, System.EventArgs e)
        {
            try
            {
                if (string.IsNullOrEmpty(txtObsDevolucao.Text.Trim()).Equals(false))
                {
                    if (Session["AvisoAnexarArquivoOficina"] != null)
                    {

                        Fs.Data.Sinistro.ArquivoAnexoSinistro oAAS = new Fs.Data.Sinistro.ArquivoAnexoSinistro();
                        oAAS.cod_aviso = int.Parse(this.txtProtocolo.Text);


                        Fs.Data.Sinistro.AvisoSinistro oAVS = new Fs.Data.Sinistro.AvisoSinistro();
                        Fs.Data.Sinistro.Orcamento oRC = new Fs.Data.Sinistro.Orcamento();
                        oAVS.cod_aviso = int.Parse(this.txtProtocolo.Text);
                        oAVS.recAvisoSinistro();

                        // Fs.Data.Sinistro.Orcamento Orc = new Fs.Data.Sinistro.Orcamento();
                        // Orc.cod_aviso= oAVS.cod_aviso;
                        // DataSet dsOrc= Orc.recOrcamentoAviso();


                        // Fs.Data.Sinistro.IndenizacaoSinistro IndSis = new Fs.Data.Sinistro.IndenizacaoSinistro();
                        Fs.Business.Sinistro.IndenizacaoSinistro IndSis = new Fs.Business.Sinistro.IndenizacaoSinistro();

                        DataSet ds = (DataSet)Session["AvisoAnexarArquivoOficina"];
                        DateTime dtSistema = DateTime.Parse(Session["DATASISTEMA"].ToString());

                        string cdusuariodevolucao = Session["USER"].ToString();
                        string MsgObsJustificativa = txtObsDevolucao.Text.Trim();

                        int cdOrc = 0;
                        short cdCompl = 0;
                        short cdParte = 0;
                        string impacto = string.Empty;

                        short tpTer = 0;
                        short cdDirec = 0;
                        short numSeq = 0;
                        int cdorgprt = 0;
                        short tporgprt = 0;


                        if (ds != null)
                        {
                            if (ds.Tables.Count > 0)
                            {

                                if (ds.Tables[0].Rows.Count > 0)
                                {
                                    int cdaviso = int.Parse(ds.Tables[0].Rows[0]["cdaviso"].ToString());
                                    int cdpester = int.Parse(ds.Tables[0].Rows[0]["cdpester"].ToString());

                                    oRC.ConnectionString = oAVS.ConnectionString;
                                    oRC.cod_aviso = oAVS.cod_aviso;
                                    oRC.cod_pessoa_terceiro = cdpester;

                                    DataSet dsOrcamento = oRC.recOrcamentoAviso();

                                    if (dsOrcamento != null)
                                    {
                                        if (dsOrcamento.Tables.Count > 0)
                                        {

                                            if (dsOrcamento.Tables[0].Rows.Count > 0)
                                            {

                                                cdOrc = int.Parse(dsOrcamento.Tables[0].Rows[dsOrcamento.Tables[0].Rows.Count - 1]["cdOrc"].ToString());
                                                cdCompl = short.Parse(dsOrcamento.Tables[0].Rows[dsOrcamento.Tables[0].Rows.Count - 1]["cdcompl"].ToString());
                                                cdParte = short.Parse(dsOrcamento.Tables[0].Rows[dsOrcamento.Tables[0].Rows.Count - 1]["cdparte"].ToString());
                                                tpTer = short.Parse(dsOrcamento.Tables[0].Rows[dsOrcamento.Tables[0].Rows.Count - 1]["tpter"].ToString());
                                                numSeq = short.Parse(dsOrcamento.Tables[0].Rows[dsOrcamento.Tables[0].Rows.Count - 1]["nrseqcom"].ToString());
                                                cdDirec = short.Parse(dsOrcamento.Tables[0].Rows[dsOrcamento.Tables[0].Rows.Count - 1]["cddirec"].ToString());
                                                // impacto = dsOrcamento.Tables[0].Rows[dsOrcamento.Tables[0].Rows.Count - 1]["impacto"].ToString();
                                            }

                                        }

                                    }


                                    //percorreo o grid capturando o status do CheckBox
                                    foreach (GridViewRow item in gvArq.Rows)
                                    {


                                        //pega dados da celula  e assim por diante
                                        var Devolver = (CheckBox)item.FindControl("chkDevolucao");


                                        if (Devolver != null)
                                        {
                                            //Verifica se o checkbox do grid esta marcado
                                            if (Devolver.Checked.Equals(true))
                                            {

                                                var darq = (Label)item.FindControl("lblcdarq");
                                                var cdTpDocumento = (Label)item.FindControl("lblcdTpDocumento");
                                                var TipoArquivo = (Label)item.FindControl("lblTipoArquivo");
                                                var DataEnvio = (Label)item.FindControl("lblDataEnvio");



                                                //realiza a Devolução do arquivo
                                                oAAS.ArqDevolverSinistroOficina(int.Parse(darq.Text.Trim()), cdaviso, cdpester,
                                                    int.Parse(cdTpDocumento.Text.Trim()),
                                                          Devolver.Checked, cdusuariodevolucao);
                                            }
                                        }

                                    }

                                    //realiza a Devolução do aviso 
                                    if (oAVS.AvisoSinistroDevolveArq(cdaviso, cdpester, MsgObsJustificativa,
                                        false, chkFaltaArq.Checked).Equals(true))
                                    {

                                        string strMensagem = string.Empty;
                                        string strErro = string.Empty;

                                        IndSis.EmailDevolverArquivos(cdaviso, cdParte, cdpester, tpTer, cdDirec, numSeq,
                                                                      cdOrc, cdCompl, cdorgprt, tporgprt, cdusuariodevolucao,
                                                                      dtSistema, MsgObsJustificativa, out strMensagem, out strErro);

                                        if (string.IsNullOrEmpty(strMensagem).Equals(true))
                                        {

                                            Session["AvisoAnexarArquivoOficina"] = null;
                                            RecuperarImagem();
                                            MessageService.Alert("Devolução realizada com sucesso !", this);
                                            btnSair_Click(null, null);
                                        }
                                        else
                                            MessageService.Alert(strMensagem, this);
                                    }
                                }
                            }
                        }

                    }
                }
                else
                {

                    MessageService.Alert("Campo Observações/Justificativa deve ser preenchido !", this);
                    OpenModal(true);
                }
            }
            catch (Exception error)
            {
                MessageService.Alert("Operação não Efetuada ! Contate Sistemas.", this);
            }
        }


        #endregion

        #region Region TabBase
        public void TabBase1_ItemClick(AlfaSegNET.Web.UI.WebControls.ToolBar.ToolBarItem itemTB)
        {
            bool flag = false;
            bool validar = true;
            bool grav = false;

            hdfIndexTabBase.Value = itemTB.AccessKey;

            if (itemTB.ItemTag == "Excluir")
            {
                #region Exclusão
                Consistent oConExcluir = new Consistent();
                oConExcluir.Add(txtProtocolo);
                oConExcluir.Add(txtIndenizacao);

                flag = oConExcluir.Consists();

                hdfIndexTabBase.Value = "4";

                if (Session["IND_KEY"] == null)
                {
                    flag = false;
                    MessageService.Alert("Registro não Recuperado !", this);
                }

                Fs.Business.Sinistro.IndenizacaoSinistro oIS = new
                    Fs.Business.Sinistro.IndenizacaoSinistro();

                if (flag)
                {
                    try
                    {
                        if (answer != null)
                        {
                            ArrayList arrKey = (ArrayList)
                                Session["IND_KEY"];

                            oIS.ReferencePage = this;
                            oIS.cod_aviso =
                                Convert.ToInt32(arrKey[0]);
                            oIS.cod_cobertura_sin =
                                Convert.ToInt16(arrKey[1]);
                            oIS.cod_pessoa =
                                Convert.ToInt32(arrKey[2]);
                            oIS.cod_indenizacao =
                                Convert.ToInt16(arrKey[3]);

                            oIS.BeginTransaction();
                            oIS.excIndenizacaoParcelaAprovaIndenizSinistro();
                            oIS.CommitTransaction();

                            oClean.Add(txtProtocolo);
                            oClean.Add(txtIndenizacao);
                            oClean.Add(ddlOperacao);
                            oClean.Add(ddlMeioPagto);
                            //oClean.Add(txtItem);
                            oClean.Add(txtBeneficiario);
                            oClean.Add(txtLiberacao);
                            oClean.Add(ddlCobertura);
                            oClean.Add(txtEntregaDoc);
                            oClean.Add(txtObservacao);
                            oClean.Add(vltxtValorMaximo);
                            oClean.Add(vltxtIndenizacao);
                            oClean.Add(vltxtPago);
                            oClean.Add(dttxtDataVencto);
                            oClean.Add(nutxtBanco);
                            oClean.Add(txtContaCorrente);
                            oClean.Add(nutxtAgencia);
                            oClean.Add(txtDigitoAg);
                            oClean.Add(txtDigitoCC);
                            oClean.Add(txtNroNF);
                            oClean.Add(txtSerieNF);
                            oClean.Add(txtValorNF);
                            #region Adicionado pela BulleST
                            oClean.Add(vlAtualizacaoMonetariaPago);
                            oClean.Add(vlCustasJudiciaisPago);
                            oClean.Add(vlHonorarioContratualPago);
                            oClean.Add(vlHonorariosAdvocaticiosPago);
                            oClean.Add(vlHonorarioSucumbenciaPago);
                            oClean.Add(vlJurosDeMoraPago);
                            oClean.Add(vlMultaPago);
                            oClean.Add(vlReservaDefesaSeguradoPago);
                            oClean.Add(vlVariacaoCambialPago);
                            oClean.Add(chkNaoIncluirAtualizacaoMonetaria);
                            oClean.Add(chkNaoIncluirCustasJudiciais);
                            oClean.Add(chkNaoIncluirHonorarioContratual);
                            oClean.Add(chkNaoIncluirHonorariosAdvocaticios);
                            oClean.Add(chkNaoIncluirHonorarioSucumbencia);
                            oClean.Add(chkNaoIncluirJurosDeMora);
                            oClean.Add(chkNaoIncluirMulta);
                            oClean.Add(chkNaoIncluirReservaDefesaSegurado);
                            oClean.Add(chkNaoIncluirVariacaoCambial);
                            #endregion

                            Clear();
                            txtProtocolo.SetFocus();
                            arrKey = null;
                            flag = false;
                            oConsistent.Reverse();
                            Session.Remove("ARRIS");
                            Session.Remove("INDENIZACAO");
                            Session.Remove("INDENIZACAO_SAVE");
                            MessageService.Alert("Registro Excluído !", this);
                        }
                        else
                        {
                            this.SavePageState();
                            Url.RedirectToMessage(this,
                                "Deseja excluir registro ?",
                                "JuridicoIndenizaDespesa.aspx",
                                TypeMessageIcon.Information,
                                0, "operation=excluir");
                            flag = false;
                        }

                        oIS = null;
                        Session["INDENIZACAO_LIMPA"] = "Delete";

                        oIS = new IndenizacaoSinistro();

                        oIS.cod_indenizacao = short.Parse(txtIndenizacao.Text.Trim());
                    }
                    catch
                    {
                        if (oIS.Transaction != null)
                        {
                            oIS.RollBackTransaction();
                            oIS = null;
                        }
                    }
                }
                #endregion
            }
            else if (itemTB.ItemTag == "Novo")
            {
                #region Limpeza
                flag = false;
                oConsistent.Reverse();
                Response.Redirect("JuridicoIndenizaDespesa.aspx?proc=new", false);
                Session["INDENIZACAO_LIMPA"] = true;
                Session.Remove("ARRIS");
                Session.Remove("INDENIZACAO");
                Session.Remove("INDENIZACAO_SAVE");
                Session.Remove("ICDAVISO");
                Session.Remove("ICDINDENIZ");
                Session.Remove("VLTXTINDENIZACAO");
                hdfIndexTabBase.Value = "1";
                txtProtocolo.Enabled = true;
                txtSequencia.Enabled = true;
                txtIndenizacao.Enabled = true;
                imbBuscaParam.Enabled = true;
                lblReabrirADM.Visible = false;
                #endregion
            }
            else if (itemTB.AccessKey == ((int)TabBaseEnum.Cancelar).ToString())
            {
                Url.NavigateUrl(this, "inicial.aspx?proc=new", "_top", 0, 0);
            }
            else if (itemTB.ItemTag == "Recuperar")
            {
                #region Recuperação
                Consistent oCon = new Consistent();

                oCon.Add(txtProtocolo);
                oCon.Add(txtIndenizacao);
                hdfIndexTabBase.Value = "2";

                if (!IsPostBack && string.IsNullOrEmpty(txtIndenizacao.Text))
                    txtIndenizacao.Text = Session["ICDINDENIZ"].ToString();

                if (oCon.Consists())
                {
                    //Consiste se terceiro tem domínio sobre o Aviso
                    if (Session["GLBCDPES"] != null && Session["GLBCDPES"].ToString().Trim() != "0")
                    {
                        AvisoSinistro oAS = new AvisoSinistro();
                        if (!oAS.recDominioProcesso(int.Parse(this.txtProtocolo.Text.Trim()),
                            int.Parse(Session["GLBCDPES"].ToString())))
                        {
                            MessageService.Alert("Processo Inexistente em sua Carteira de Clientes!", this);
                            return;
                        }
                    }

                    oConsistent.Reverse();
                    oCon.Reverse();
                    RecParametros(false);
                    Session["ICDAVISO"] = this.txtProtocolo.Text.Trim();
                    Session["ICDINDENIZ"] = this.txtIndenizacao.Text.Trim();
                    Session["VLTXTINDENIZACAO"] = this.vltxtIndenizacao.Text.Trim();

                    //Repopula combo quando da chamada para recuperar novo Protocolo

                    Session.Remove("PCDCONSEG");
                    Session.Remove("PCDEMI");
                    Util.MontarDDLAcessoRapido(ref this.QuickAccess1, (DataSet)Session["ALLACCESS"], "Jurídico", this.txtProtocolo.Text, "", "", (Session["TP"] == null || Session["TP"].ToString() == "0"));
                    this.QuickAccess1.SelectedIndex = 0;

                    this.GerenciarStatus();

                }
                #endregion
            }
            else if (itemTB.ItemTag == "Pesquisar")
            {
                hdfIndexTabBase.Value = "6";
                Session["Indenizacao"] = null;
                Response.Redirect("PesquisaIndenizacoes.aspx", false);
            }
            else if (itemTB.ItemTag == "Gravar")
            {
                #region Validações
                hdfIndexTabBase.Value = "3";

                decimal vlindenizacao = 0;

                if (!chkNaoIncluirReservaDefesaSegurado.Checked && chkNaoIncluirReservaDefesaSegurado.Enabled)
                {
                    decimal vlreservadefseg = decimal.Parse(vlReservaDefesaSeguradoPago.Text.Trim());
                    decimal vlhonorariosadv = !chkNaoIncluirHonorariosAdvocaticios.Checked ? decimal.Parse(vlHonorariosAdvocaticiosPago.Text.Trim()) : 0;
                    vlindenizacao = vlreservadefseg + vlhonorariosadv;
                }
                else
                    vlindenizacao = !string.IsNullOrEmpty(vltxtIndenizacao.Text) ? decimal.Parse(vltxtIndenizacao.Text.Trim()) : 0;

                vltxtIndenizacao.Text = Formatter.FormatCurrency(vlindenizacao);

                if (vlindenizacao != 0 && !string.IsNullOrEmpty(vltxtPago.Text) && !string.IsNullOrEmpty(vltxtValorMaximo.Text))
                {
                    decimal valorMaximo = decimal.Parse(vltxtValorMaximo.Text.Trim());
                    decimal valorPago = decimal.Parse(vltxtPago.Text.Trim());

                    if (valorMaximo < valorPago)
                    {
                        string msgAlert = "Valor máximo inferior ao valor pago, favor alterar valor da provisão";
                        MessageService.Alert(msgAlert, this);
                        flag = false;
                        validar = false;
                        vltxtIndenizacao.SetFocus();
                    }
                    else
                    {
                        decimal valorPermitido = (valorMaximo - valorPago);

                        if (valorPermitido < vlindenizacao)
                        {
                            string msgAlert = "Valor Máximo de Indenização Excedido, o valor máximo permitido para esta indenização é R$" + Formatter.FormatCurrency(valorPermitido);
                            MessageService.Alert(msgAlert, this);
                            flag = false;
                            validar = false;
                            vltxtIndenizacao.SetFocus();
                        }
                    }
                }

                if (this.ddlMeioPagto.SelectedValue.Trim() == "0")
                {
                    MessageService.Alert("Selecionar Forma de Pagamento !", this);
                    flag = false;
                    validar = false;
                    vltxtIndenizacao.SetFocus();
                }

                oConsistent.Add(dttxtDataVencto);

                if (!string.IsNullOrEmpty(vltxtIndenizacao.Text))
                {
                    decimal totaldespesas = 0;

                    totaldespesas += string.IsNullOrEmpty(vlAtualizacaoMonetariaPago.Text) ? 0 : decimal.Parse(vlAtualizacaoMonetariaPago.Text.Trim());
                    totaldespesas += string.IsNullOrEmpty(vlCustasJudiciaisPago.Text) ? 0 : decimal.Parse(vlCustasJudiciaisPago.Text.Trim());
                    totaldespesas += string.IsNullOrEmpty(vlHonorarioContratualPago.Text) ? 0 : decimal.Parse(vlHonorarioContratualPago.Text.Trim());
                    totaldespesas += string.IsNullOrEmpty(vlHonorariosAdvocaticiosPago.Text) ? 0 : decimal.Parse(vlHonorariosAdvocaticiosPago.Text.Trim());
                    totaldespesas += string.IsNullOrEmpty(vlHonorarioSucumbenciaPago.Text) ? 0 : decimal.Parse(vlHonorarioSucumbenciaPago.Text.Trim());
                    totaldespesas += string.IsNullOrEmpty(vlJurosDeMoraPago.Text) ? 0 : decimal.Parse(vlJurosDeMoraPago.Text.Trim());
                    totaldespesas += string.IsNullOrEmpty(vlMultaPago.Text) ? 0 : decimal.Parse(vlMultaPago.Text.Trim());
                    totaldespesas += string.IsNullOrEmpty(vlReservaDefesaSeguradoPago.Text) ? 0 : decimal.Parse(vlReservaDefesaSeguradoPago.Text.Trim());
                    totaldespesas += string.IsNullOrEmpty(vlVariacaoCambialPago.Text) ? 0 : decimal.Parse(vlVariacaoCambialPago.Text.Trim());

                    if (totaldespesas == 0 && Convert.ToDecimal(vltxtIndenizacao.Text.Trim()) <= 0)
                    {
                        MessageService.Alert("Valor Indenizacao não Permitido !", this);
                        flag = false;
                        validar = false;
                    }
                }

                if (!string.IsNullOrEmpty(dttxtDataVencto.Text))
                {
                    if (Convert.ToDateTime(dttxtDataVencto.Text) < Convert.ToDateTime(Session["DATASISTEMA"]))
                    {
                        MessageService.Alert("Data Vencimento deve ser maior que a data do Sistema !", this);
                        flag = false;
                        validar = false;
                        dttxtDataVencto.SetFocus();
                    }
                }

                if (Session["IDPESSOA"] == null)
                {
                    flag = false;
                    validar = false;
                    MessageService.Alert("Informar o Beneficiário !", this);
                }

                if (Session["CDORGAO"] == null || Session["TIPOORGAO"] == null)
                {
                    flag = false;
                    validar = false;
                    MessageService.Alert("Cadastrar Orgão Produtor !", this);
                }

                //if (!string.IsNullOrEmpty(this.ddlOperacao.SelectedValue))
                //{
                //    Fs.Business.Financeiro.Operacao oOP = new Fs.Business.Financeiro.Operacao();
                //    oOP.cod_operacao = int.Parse(this.ddlOperacao.SelectedValue.Trim());
                //    DataSet dsOperacao = oOP.recOperacao();

                //    if (dsOperacao.Tables[0].Rows[0]["incalciss"] != null
                //        && dsOperacao.Tables[0].Rows[0]["incalciss"].ToString().Trim().ToUpper() == "S"
                //        && (this.ddlTpServico.SelectedIndex == -1 || this.ddlTpServico.SelectedValue.Trim().Length == 0))
                //    {
                //        flag = false;
                //        validar = false;
                //        MessageService.Alert("Tipo de Servião é Obrigatário para Operações Tributáveis !", this);
                //    }
                //    if (dsOperacao.Tables[0].Rows[0]["incalciss"] != null
                //        && dsOperacao.Tables[0].Rows[0]["incalciss"].ToString().Trim().ToUpper() == "S"
                //        && (this.txtNroNF.Text.Trim().Length == 0 || this.txtNroNF.Text.Trim() == "0"))
                //    {
                //        flag = false;
                //        validar = false;
                //        MessageService.Alert("Obrigatário Cadastro de Nota Fiscal !", this);
                //    }
                //}

                if (validar)
                {
                    this.ddlMeioPagto_SelectedIndexChanged(null, null);

                    flag = oConsistent.Consists();

                    //if (flag)
                    //{
                    //    flag = ValidarBoletoBancário();
                    //    if (!flag)
                    //        MessageService.Alert("Faltam caracteres no boleto bancário!", this);
                    //}
                }

                if (flag)
                {
                    DateTime dtVenc = DateTime.Parse(this.dttxtDataVencto.Text.Trim());

                    if (Convert.ToDateTime(Session["DATASISTEMA"]).AddDays(30) < dtVenc)
                        MessageService.Alert("Data de Vencimento Superior a 30 dias !", this);

                    if (
                    !chkNaoIncluirAtualizacaoMonetaria.Checked && chkNaoIncluirAtualizacaoMonetaria.Enabled && string.IsNullOrEmpty(vlAtualizacaoMonetariaPago.Text)
                    || !chkNaoIncluirCustasJudiciais.Checked && chkNaoIncluirCustasJudiciais.Enabled && string.IsNullOrEmpty(vlCustasJudiciaisPago.Text)
                    || !chkNaoIncluirHonorarioContratual.Checked && chkNaoIncluirHonorarioContratual.Enabled && string.IsNullOrEmpty(vlHonorarioContratualPago.Text)
                    || !chkNaoIncluirHonorariosAdvocaticios.Checked && chkNaoIncluirHonorariosAdvocaticios.Enabled && string.IsNullOrEmpty(vlHonorariosAdvocaticiosPago.Text)
                    || !chkNaoIncluirHonorarioSucumbencia.Checked && chkNaoIncluirHonorarioSucumbencia.Enabled && string.IsNullOrEmpty(vlHonorarioSucumbenciaPago.Text)
                    || !chkNaoIncluirJurosDeMora.Checked && chkNaoIncluirJurosDeMora.Enabled && string.IsNullOrEmpty(vlJurosDeMoraPago.Text)
                    || !chkNaoIncluirMulta.Checked && chkNaoIncluirMulta.Enabled && string.IsNullOrEmpty(vlMultaPago.Text)
                    || !chkNaoIncluirReservaDefesaSegurado.Checked && chkNaoIncluirReservaDefesaSegurado.Enabled && string.IsNullOrEmpty(vlReservaDefesaSeguradoPago.Text)
                        //|| !chkNaoIncluirVariacaoCambial.Checked && chkNaoIncluirVariacaoCambial.Enabled && string.IsNullOrEmpty(vlVariacaoCambialPago.Text)
                    )
                    {
                        flag = false;
                        MessageService.Alert("É preciso informar o quanto vai pagar de cada despesa !", this);
                    }
                }
                #endregion
                grav = true;
            }
            else if (itemTB.ItemTag == "Excluir")
            {
                hdfIndexTabBase.Value = "4";
                #region Validações
                if (Session["IDPESSOA"] == null)
                {
                    flag = false;
                    validar = false;
                }

                if (validar)
                    flag = oConsistent.Consists();

                #endregion
            }

            if (flag)
            {
                Fs.Business.Sinistro.IndenizacaoSinistro oIS = new Fs.Business.Sinistro.IndenizacaoSinistro();

                #region Required Configuration Properties IndenizacaoSinistro
                //set type database
                oIS.DataBase = DataBaseEnum.SqlServer;
                //set to TabIndex 
                oIS.SelectedIndex = Convert.ToInt32(hdfIndexTabBase.Value);
                //set to reference page
                oIS.ReferencePage = this;
                //set to reference clean
                oIS.ReferenceClean = oClean;
                #endregion

                #region Populate the properties de IS
                oIS.cod_pessoa = Convert.ToInt32(Session["IDPESSOA"]);
                oIS.cod_aviso = int.Parse(txtProtocolo.Text.Trim());

                if (!string.IsNullOrEmpty(txtIndenizacao.Text))
                    oIS.cod_indenizacao = short.Parse(txtIndenizacao.Text);

                oIS.cod_cobertura_sin = short.Parse(ddlCobertura.SelectedItem.Value);
                oIS.cod_ramo = Convert.ToInt16(Session["RAMO"]);
                oIS.cod_sub_ramo = Convert.ToInt16(Session["SUBRAMO"]);
                oIS.cod_usuario = Session["USER"].ToString();
                oIS.cod_referencia_monetaria = short.Parse(ddlReferencia.SelectedItem.Value);
                oIS.data_referencia = Convert.ToDateTime(dttxtDataVencto.Text);
                oIS.cddirec = short.Parse(txtSequencia.Text.Trim());

                if (string.IsNullOrEmpty(txtSolicitacao.Text))
                    oIS.data_geracao = Convert.ToDateTime("01/01/1901");
                else
                    oIS.data_geracao = DateTime.Parse(txtSolicitacao.Text);

                if (txtLiberacao.Text.Trim() == "")
                    oIS.data_liberacao = Convert.ToDateTime("01/01/1901");
                else
                    oIS.data_liberacao = DateTime.Parse(txtLiberacao.Text);

                if (rblLiquidacao.SelectedIndex == 0)
                    oIS.perc_participacao = 2;
                else
                    oIS.perc_participacao = Convert.ToDecimal(rblLiquidacao.SelectedIndex);

                oIS.qtde_parcelas = 1;

                if (txtSituacao.Text == "Pendente" || string.IsNullOrEmpty(txtSituacao.Text))
                    oIS.tipo_situacao = 0;
                else if (txtSituacao.Text == "Liberado")
                    oIS.tipo_situacao = 1;
                else if (txtSituacao.Text == "Pago")
                    oIS.tipo_situacao = 2;
                else
                    oIS.tipo_situacao = 5;

                if (!string.IsNullOrEmpty(vltxtIndenizacao.Text.Trim()))
                    oIS.val_indenizacao = decimal.Parse(vltxtIndenizacao.Text);

                if (!string.IsNullOrEmpty(vltxtPago.Text.Trim()))
                    oIS.val_pago = decimal.Parse(vltxtPago.Text);

                oIS.obs_2 = txtObs.Text;

                if (nutxtBanco.Text.Trim() != "")
                    oIS.cod_banco = short.Parse(nutxtBanco.Text);
                if (nutxtAgencia.Text.Trim() != "")
                    oIS.cod_agencia = int.Parse(nutxtAgencia.Text);

                if (!string.IsNullOrEmpty(txtContaCorrente.Text))
                    oIS.num_conta_corrente = txtContaCorrente.Text;
                else
                    oIS.num_conta_corrente = "";

                oIS.tipo_docto_pagto = short.Parse(ddlMeioPagto.SelectedItem.Value);

                if (!string.IsNullOrEmpty(txtDigitoAg.Text))
                    oIS.digito_agencia = txtDigitoAg.Text;
                else
                    oIS.digito_agencia = "";

                if (!string.IsNullOrEmpty(txtDigitoCC.Text))
                    oIS.digito_conta_corrente = txtDigitoCC.Text;
                else
                    oIS.digito_conta_corrente = "";

                oIS.cod_operacao = int.Parse(ddlOperacao.SelectedItem.Value);
                oIS.ind_benef_concedido = "N";
                oIS.qtde_parc_beneficio = 0;
                oIS.cod_orgao_produtor = Convert.ToInt32(Session["CDORGAO"]);
                oIS.tipo_orgao_produtor = Convert.ToInt16(Session["TIPOORGAO"]);
                oIS.nro_nota_fiscal = txtNroNF.Text.Trim() == "" ? 0 : int.Parse(txtNroNF.Text);
                oIS.serie_nota_fiscal = string.IsNullOrEmpty(txtSerieNF.Text) ? "" : txtSerieNF.Text.Trim();

                if (this.ddlTpServico.SelectedIndex == 0 || this.ddlTpServico.SelectedIndex == -1)
                    oIS.cod_tipo_pessoa = -1;
                else
                    oIS.cod_tipo_pessoa = int.Parse(this.ddlTpServico.SelectedValue.Trim());

                oIS.ind_correcao_monetaria = "N";

                #region verifica se é defesa do segurado, para colocar indicador de ação judicial ou não
                DadosJudiciais oDJ = new DadosJudiciais();
                oDJ.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
                oDJ.cod_direcionamento = short.Parse(txtSequencia.Text.Trim());
                oDJ.cod_pester = string.IsNullOrEmpty(Request.QueryString["cdpester"]) ? -1 : int.Parse(Request.QueryString["cdpester"]);
                oDJ.tipo_terceiro = string.IsNullOrEmpty(Request.QueryString["tpter"]) ? (short)-1 : short.Parse(Request.QueryString["tpter"]);

                oDJ.recDadosJudiciaisTerceiro();

                oIS.ind_acao_judicial = oDJ.ind_defesa_segurado == 1 ? "N" : "S";
                #endregion

                oIS.tpindenizacao = 2;



                //Verifica se o pagamento é boleto bancário, para pegar o código de barras
                if (oIS.tipo_docto_pagto == 4)
                {
                    System.Text.StringBuilder sb = new System.Text.StringBuilder();
                    sb.Append(nuNrCodBarras1.Text.Trim());
                    sb.Append(nuNrCodBarras2.Text.Trim());
                    sb.Append(nuNrCodBarras3.Text.Trim());
                    sb.Append(nuNrCodBarras4.Text.Trim());
                    sb.Append(nuNrCodBarras5.Text.Trim());
                    sb.Append(nuNrCodBarras6.Text.Trim());
                    sb.Append(nuNrCodBarras7.Text.Trim());
                    sb.Append(nuNrCodBarras8.Text.Trim());

                    oIS.nrcodbarr = sb.ToString();
                }
                //Caso seja cheque, pegar a observação
                else if (oIS.tipo_docto_pagto == 1)
                    oIS.desc_obs = txtObsCheque.Text.Trim();

                if (!chkNaoIncluirAtualizacaoMonetaria.Checked && chkNaoIncluirAtualizacaoMonetaria.Enabled)
                    oIS.vlpagoatualizacaomonetariaacjud = Convert.ToDecimal(vlAtualizacaoMonetariaPago.Text.Trim());

                if (!chkNaoIncluirCustasJudiciais.Checked && chkNaoIncluirCustasJudiciais.Enabled)
                    oIS.vlpagocustajudicial = Convert.ToDecimal(vlCustasJudiciaisPago.Text.Trim());

                if (!chkNaoIncluirHonorarioContratual.Checked && chkNaoIncluirHonorarioContratual.Enabled)
                    oIS.vlpagohonorariocontratual = Convert.ToDecimal(vlHonorarioContratualPago.Text.Trim());

                if (!chkNaoIncluirHonorariosAdvocaticios.Checked && chkNaoIncluirHonorariosAdvocaticios.Enabled)
                    oIS.vlpagohonorariosadvocaticios = Convert.ToDecimal(vlHonorariosAdvocaticiosPago.Text.Trim());

                if (!chkNaoIncluirHonorarioSucumbencia.Checked && chkNaoIncluirHonorarioSucumbencia.Enabled)
                    oIS.vlpagosucumbencia = Convert.ToDecimal(vlHonorarioSucumbenciaPago.Text.Trim());

                if (!chkNaoIncluirJurosDeMora.Checked && chkNaoIncluirJurosDeMora.Enabled)
                    oIS.vlpagojurosacjud = Convert.ToDecimal(vlJurosDeMoraPago.Text.Trim());

                if (!chkNaoIncluirMulta.Checked && chkNaoIncluirMulta.Enabled)
                    oIS.vlpagomultaacjud = Convert.ToDecimal(vlMultaPago.Text.Trim());

                if (!chkNaoIncluirReservaDefesaSegurado.Checked && chkNaoIncluirReservaDefesaSegurado.Enabled)
                    oIS.vlpagoreservadefesasegurado = Convert.ToDecimal(vlReservaDefesaSeguradoPago.Text.Trim());

                //if (!chkNaoIncluirVariacaoCambial.Checked && chkNaoIncluirVariacaoCambial.Enabled)
                //    oIS.vlpagovarcambialacjud = Convert.ToDecimal(vlVariacaoCambialPago.Text.Trim());

                oIS.inatualizacaomonetariaacjud = chkNaoIncluirAtualizacaoMonetaria.Checked ? 1 : 0;
                oIS.incustasjudiciais = chkNaoIncluirCustasJudiciais.Checked ? 1 : 0;
                oIS.inhonorariocontratual = chkNaoIncluirHonorarioContratual.Checked ? 1 : 0;
                oIS.inhonorariosadvocaticios = chkNaoIncluirHonorariosAdvocaticios.Checked ? 1 : 0;
                oIS.inhonorariosucumbencia = chkNaoIncluirHonorarioSucumbencia.Checked ? 1 : 0;
                oIS.injurosacjud = chkNaoIncluirJurosDeMora.Checked ? 1 : 0;
                oIS.inmultaacjud = chkNaoIncluirMulta.Checked ? 1 : 0;
                oIS.inreservadefesasegurado = chkNaoIncluirReservaDefesaSegurado.Checked ? 1 : 0;
                //oIS.invarcambialacjud = chkNaoIncluirVariacaoCambial.Checked ? 1 : 0;
                oIS.invarcambialacjud = 1;

                if (oIS.vlpagoreservadefesasegurado > 0)
                    oIS.val_indenizacao = oIS.vlpagoreservadefesasegurado + oIS.vlpagohonorariosadvocaticios;

                oIS.vlpagoacao = oIS.val_indenizacao;

                oIS.cdpester = string.IsNullOrEmpty(Request.QueryString["cdpester"]) ? -1 : int.Parse(Request.QueryString["cdpester"]);
                oIS.tpter = string.IsNullOrEmpty(Request.QueryString["tpter"]) ? (short)-1 : short.Parse(Request.QueryString["tpter"]);

                this.SavePageState();

                if (ddlCobertura.Items.Count > 1)
                    Session["INDENIZACAOCOB"] = ddlCobertura.SelectedIndex;

                #endregion

                #region Populate the properties de PS
                Fs.Business.Sinistro.ParcelaSinistro oPS = new Fs.Business.Sinistro.ParcelaSinistro();

                oPS.DataBase = DataBaseEnum.SqlServer;
                oPS.ReferencePage = this;
                oPS.ReferenceClean = oClean;

                if (this.TotalRegistrosEmParcelas() <= 1)
                {
                    ArrayList arrPS1 = new ArrayList();
                    if (dttxtDataVencto.Text.Trim() != "")
                    {
                        oPS.cod_referencia_monetaria = short.Parse(ddlReferencia.SelectedItem.Value);
                        oPS.data_vencimento = Convert.ToDateTime(dttxtDataVencto.Text);
                        oPS.data_pagto = Convert.ToDateTime("01/01/1901");

                        if (txtSolicitacao.Text.Trim() != "")
                            oPS.data_geracao = Convert.ToDateTime(txtSolicitacao.Text);
                        else
                            oPS.data_geracao = Convert.ToDateTime("01/01/1901");

                        if (txtSituacao.Text == "Pendente" || string.IsNullOrEmpty(txtSituacao.Text))
                            oPS.tipo_parcela = 0;
                        else if (txtSituacao.Text == "Liberado")
                            oPS.tipo_parcela = 1;
                        else if (txtSituacao.Text == "Pago")
                            oPS.tipo_parcela = 2;
                        else
                            oPS.tipo_parcela = 5;

                        oPS.cod_pessoa = Convert.ToInt32(Session["IDPESSOA"]);
                        oPS.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
                        oPS.cod_cobertura_sin = short.Parse(ddlCobertura.SelectedItem.Value);

                        if (txtIndenizacao.Text.Trim() != "")
                            oPS.cod_indenizacao = short.Parse(txtIndenizacao.Text.Trim());

                        arrPS1.Add(oPS);
                        oIS.ReferencePS = arrPS1;
                    }
                    else
                        MessageService.Alert("Informar Data Vencimento !", this);
                }
                else
                {
                    ArrayList arrPS = new ArrayList();
                    if (Session["ARRIS"] == null)
                    {
                        DataSet dsPS = (DataSet)Session["INDENIZACAO"];

                        DataRow[] drNoNull = dsPS.Tables[0].Select("cdpes is not null");

                        for (int count = 0; count < drNoNull.Length; count++)
                        {
                            Fs.Business.Sinistro.ParcelaSinistro oPS1 = new Fs.Business.Sinistro.ParcelaSinistro();

                            oPS1.data_vencimento = Convert.ToDateTime(drNoNull[count]["dtven"]);

                            if (drNoNull[count]["dtpagto"].ToString() != "" && !drNoNull[count].IsNull("dtpagto"))
                                oPS1.data_pagto = Convert.ToDateTime(drNoNull[count]["dtpagto"]);
                            else
                                oPS1.data_pagto = Convert.ToDateTime("01/01/1901");

                            oPS1.val_parcela = Convert.ToDecimal(drNoNull[count]["vlparc"]);

                            oPS1.val_corr_beneficio_con = Convert.ToDecimal(drNoNull[count]["vlcorrbencon"]);

                            oPS1.tipo_parcela = Convert.ToInt16(drNoNull[count]["stparcela"]);

                            if (drNoNull[count]["cdparsin"] != System.DBNull.Value)
                                oPS1.cod_parcela_sin = Convert.ToInt16(drNoNull[count]["cdparsin"]);

                            oPS1.cod_pessoa = Convert.ToInt32(Session["IDPESSOA"]);
                            oPS1.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
                            oPS1.cod_cobertura_sin = short.Parse(ddlCobertura.SelectedItem.Value);

                            if (txtIndenizacao.Text.Trim() != "")
                                oPS1.cod_indenizacao = short.Parse(txtIndenizacao.Text.Trim());

                            oPS1.cod_referencia_monetaria = short.Parse(ddlReferencia.SelectedItem.Value);
                            oPS1.data_geracao = Convert.ToDateTime(txtSolicitacao.Text);

                            bool flg = bool.Parse(AspNetFindControl.GetValueTemplateColumnOtherPage((Page)this, "dgParcelas", "cbDelete", count));

                            oPS1.Flag = flg;
                            arrPS.Add(oPS1);
                        }
                    }

                    if (Session["ARRIS"] != null)
                    {
                        oIS.ReferencePS = (ArrayList)Session["ARRIS"];
                        Session.Remove("ARRIS");
                    }
                    else
                    {
                        oIS.ReferencePS = arrPS;
                        Session["ARRIS"] = arrPS;
                    }
                }
                #endregion

                try
                {
                    #region Realizar Gravação e Exclusão
                    oIS.ReferencePage = this;
                    oIS.Answer = answer;

                    oIS.TransactCoordinator();

                    if (oIS.Answer == null && oIS.Operation != null)
                        Response.Redirect(oIS.UrlMessage, false);
                    else
                    {
                        Session.Remove("IND_ARRDIS");
                        Session.Remove("IND_ARRCDDELETE");

                        txtIndenizacao.Text = oIS.cod_indenizacao.ToString();

                        if (grav && this.txtcdsolpag.Text.Trim().Length > 0)
                        {
                            SolicitaPagamento oSol = new SolicitaPagamento();
                            oSol.cod_aviso = int.Parse(this.txtProtocolo.Text.Trim());
                            oSol.cod_solpag = short.Parse(this.txtcdsolpag.Text.Trim());
                            oSol.recSolicitaPagamento();

                            oSol.status = "Efetuado";
                            oSol.cod_cobertura = short.Parse(this.ddlCobertura.SelectedValue.Trim());
                            oSol.cod_indeniz = short.Parse(this.txtIndenizacao.Text.Trim());
                            oSol.atuSolicitaPagamento();
                        }
                    }

                    oIS = null;

                    #endregion
                }
                catch
                {
                    if (oIS.Transaction != null)
                    {
                        oIS.RollBackTransaction();
                        oIS = null;
                    }
                }
                Session["INDENIZACAO"] = null;
                txtProtocolo.SetFocus();

                this.Recuperar();

                MessageService.Alert("Gravação Efetuada !", this);
            }

            //return the inicial index
            itemTB.ItemTag = "";
        }
        #endregion

        protected void rblLiquidacao_SelectedIndexChanged(object sender, EventArgs e)
        {
            string tpliquidacao = rblLiquidacao.SelectedValue;

            if (tpliquidacao == "1")
                lblReabrirADM.Visible = false;
            else
            {
                string cdaviso = txtProtocolo.Text;
                if (!string.IsNullOrEmpty(cdaviso))
                {
                    AvisoSinistro oAS = new AvisoSinistro();
                    oAS.cod_aviso = int.Parse(cdaviso);
                    oAS.recAvisoSinistro();

                    if (oAS.RecordCount > 0)
                    {
                        if (oAS.tipo_situacao == 3 || oAS.tipo_situacao == 4)
                            lblReabrirADM.Visible = true;
                    }
                }
            }
        }

        private bool ValidarBoletoBancário()
        {
            string controlname = "nuNrCodBarras";
            bool result = true;
            for (int i = 1; i <= 8; i++)
            {
                Fs.Web.UI.WebControls.Numero controle = (Fs.Web.UI.WebControls.Numero)FindControl(controlname + i);
                if (controle.Text.Trim().Length != controle.MaxLength)
                {
                    oConsistent.ConfigureObject(controle, true);
                    result = false;
                }
            }

            return result;
        }

        #region CancelIndenizacao
        private bool CancelIndenizacao(out string warning)
        {
            warning = null;

            Fs.Business.Sinistro.AvisoSinistro oAS = new Fs.Business.Sinistro.AvisoSinistro();
            Fs.Business.Sinistro.IndenizacaoSinistro oIS = new Fs.Business.Sinistro.IndenizacaoSinistro();

            oAS.ReferencePage = this;
            oAS.cod_aviso = int.Parse(txtProtocolo.Text);
            try
            {
                oAS.recAvisoSinistro();
            }
            catch { }

            if (oAS.tipo_situacao != Convert.ToInt32(TabFooterCOMEnum.Avisado))
            {
                warning = "Esta Indenização não pode ser cancelada. ";
                warning += "O aviso de sinistro está pendente, encerrado ou já foi liquidado.";
                return false;
            }
            else
            {
                oIS.ReferencePage = this;
                oIS.cod_aviso = int.Parse(txtProtocolo.Text);
                oIS.cod_cobertura_sin = short.Parse(ddlCobertura.SelectedItem.Value);
                oIS.cod_pessoa = Convert.ToInt32(Session["IDPESSOA"]);
                oIS.cod_indenizacao = short.Parse(txtIndenizacao.Text);
                oIS.cod_usuario = Session["USER"].ToString();
                oIS.BeginTransaction();
                try
                {
                    oIS.atuCancelaIndenizacaoSinistro();
                    oIS.CommitTransaction();
                }
                catch
                {
                    oIS.RollBackTransaction();
                    warning = "Erro no Cancelamento. Contate Sistemas !";
                    return false;
                }
            }

            oAS = null;
            oIS = null;

            return true;
        }
        #endregion

        #region TabFooter
        private void TabFooterIndenizacao_SelectedIndexChange(object sender, MenuEventArgs e)
        {
            string warning = null;
            bool flag = false;

            string EvenValue = "";

            if (e != null)
            {
                if (e.Item.Value != null)
                    EvenValue = e.Item.Value;
                else
                    EvenValue = hdfTabFooterSelectedIndex.Value;
            }
            else
                EvenValue = hdfTabFooterSelectedIndex.Value;

            if (Session["ICDAVISO"] == null || Session["ICDINDENIZ"] == null)
                return;

            if (Session["ICDAVISO"].ToString() != this.txtProtocolo.Text.Trim() || Session["ICDINDENIZ"].ToString() != this.txtIndenizacao.Text.Trim())
            {
                MessageService.Alert("Recupere a Indenização alvo da Liberação!", this);

                return;
            }

            if (Session["VLTXTINDENIZACAO"].ToString() != this.vltxtIndenizacao.Text.Trim())
            {
                MessageService.Alert("Grave a alteração de Valor antes da Liberação!", this);

                return;
            }

            if (Convert.ToInt32(EvenValue) == (int)TabFooterIndenixEnum.Liberar || Convert.ToInt32(hdfTabFooterSelectedIndex.Value) == (int)TabFooterIndenixEnum.Liberar)
            {
                if (!Access.ValidateOneItem((DataSet)Session["ALLACCESS"], "JudIndeniza.pbLiberar", Session["_ACT_MODULE"].ToString(), FunctionEnum.EFE))
                {
                    MessageService.Alert("Usuário não Autorizado.", this);
                    return;
                }

                if (Session["LIBPARCELAS"] != null)
                {
                    DataSet dsPar = (DataSet)Session["LIBPARCELAS"];
                    dttxtDataVencto.Text = Transformer.CheckValue(Convert.ToDateTime(dsPar.Tables[0].Rows[0]["dtven"]));
                    dsPar = null;
                }

                var liberacaoOficina = txtSituacao.Text == "Pendente" ? true : false;

                Fs.Business.Sinistro.IndenizacaoSinistro oIS = new Fs.Business.Sinistro.IndenizacaoSinistro();
                oIS.ReferencePage = this;

                int inatualizacaomonetariaacjud, incustasjudiciais, inhonorariocontratual, inhonorariosadvocaticios, inhonorariosucumbencia, injurosacjud, inmultaacjud, inreservadefesasegurado, invarcambialacjud;
                decimal vlpagoatualizacaomonetariaacjud = 0, vlpagocustajudicial = 0, vlpagohonorariocontratual = 0, vlpagohonorariosadvocaticios = 0, vlpagosucumbencia = 0, vlpagojurosacjud = 0, vlpagomultaacjud = 0, vlpagoreservadefesasegurado = 0, vlpagovarcambialacjud = 0;
                string strindacaojud = "";
                short cddirec = 0;

                if (!chkNaoIncluirAtualizacaoMonetaria.Checked && chkNaoIncluirAtualizacaoMonetaria.Enabled)
                    vlpagoatualizacaomonetariaacjud = Convert.ToDecimal(vlAtualizacaoMonetariaPago.Text.Trim());

                if (!chkNaoIncluirCustasJudiciais.Checked && chkNaoIncluirCustasJudiciais.Enabled)
                    vlpagocustajudicial = Convert.ToDecimal(vlCustasJudiciaisPago.Text.Trim());

                if (!chkNaoIncluirHonorarioContratual.Checked && chkNaoIncluirHonorarioContratual.Enabled)
                    vlpagohonorariocontratual = Convert.ToDecimal(vlHonorarioContratualPago.Text.Trim());

                if (!chkNaoIncluirHonorariosAdvocaticios.Checked && chkNaoIncluirHonorariosAdvocaticios.Enabled)
                    vlpagohonorariosadvocaticios = Convert.ToDecimal(vlHonorariosAdvocaticiosPago.Text.Trim());

                if (!chkNaoIncluirHonorarioSucumbencia.Checked && chkNaoIncluirHonorarioSucumbencia.Enabled)
                    vlpagosucumbencia = Convert.ToDecimal(vlHonorarioSucumbenciaPago.Text.Trim());

                if (!chkNaoIncluirJurosDeMora.Checked && chkNaoIncluirJurosDeMora.Enabled)
                    vlpagojurosacjud = Convert.ToDecimal(vlJurosDeMoraPago.Text.Trim());

                if (!chkNaoIncluirMulta.Checked && chkNaoIncluirMulta.Enabled)
                    vlpagomultaacjud = Convert.ToDecimal(vlMultaPago.Text.Trim());

                if (!chkNaoIncluirReservaDefesaSegurado.Checked && chkNaoIncluirReservaDefesaSegurado.Enabled)
                    vlpagoreservadefesasegurado = Convert.ToDecimal(vlReservaDefesaSeguradoPago.Text.Trim());

                //if (!chkNaoIncluirVariacaoCambial.Checked && chkNaoIncluirVariacaoCambial.Enabled)
                //    vlpagovarcambialacjud = Convert.ToDecimal(vlVariacaoCambialPago.Text.Trim());

                inatualizacaomonetariaacjud = chkNaoIncluirAtualizacaoMonetaria.Checked ? 1 : 0;
                incustasjudiciais = chkNaoIncluirCustasJudiciais.Checked ? 1 : 0;
                inhonorariocontratual = chkNaoIncluirHonorarioContratual.Checked ? 1 : 0;
                inhonorariosadvocaticios = chkNaoIncluirHonorariosAdvocaticios.Checked ? 1 : 0;
                inhonorariosucumbencia = chkNaoIncluirHonorarioSucumbencia.Checked ? 1 : 0;
                injurosacjud = chkNaoIncluirJurosDeMora.Checked ? 1 : 0;
                inmultaacjud = chkNaoIncluirMulta.Checked ? 1 : 0;
                inreservadefesasegurado = chkNaoIncluirReservaDefesaSegurado.Checked ? 1 : 0;
                //invarcambialacjud = chkNaoIncluirVariacaoCambial.Checked ? 1 : 0;
                invarcambialacjud = 1;

                decimal vlindenizacao = decimal.Parse(vltxtIndenizacao.Text.Trim());

                DadosJudiciais oDJ = new DadosJudiciais();
                oDJ.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
                oDJ.cod_direcionamento = short.Parse(txtSequencia.Text.Trim());
                oDJ.cod_pester = string.IsNullOrEmpty(Request.QueryString["cdpester"]) ? -1 : int.Parse(Request.QueryString["cdpester"]);
                oDJ.tipo_terceiro = string.IsNullOrEmpty(Request.QueryString["tpter"]) ? (short)-1 : short.Parse(Request.QueryString["tpter"]);

                oDJ.recDadosJudiciaisTerceiro();

                strindacaojud = oDJ.ind_defesa_segurado == 1 ? "N" : "S";
                cddirec = oDJ.cod_direcionamento;

                flag = oIS.ConsisteLiberaIndenizacao(int.Parse(txtProtocolo.Text.Trim()),
                      short.Parse(txtIndenizacao.Text.Trim()),
                      short.Parse(ddlCobertura.SelectedItem.Value),
                      int.Parse(Session["IDPESSOA"].ToString().Trim()),
                      rblLiquidacao.Items[Convert.ToInt32(LiquidacaoEnum.Parcial)].Selected,
                      rblLiquidacao.Items[Convert.ToInt32(LiquidacaoEnum.Total)].Selected,
                      Convert.ToDateTime(dttxtDataVencto.Text),
                      decimal.Parse(vltxtIndenizacao.Text.Trim()),
                      idget, answer, "", DateTime.Parse(Session["DATASISTEMA"].ToString()),
                      Session["USER"].ToString(), liberacaoOficina, 2,
                      0, 0, 0, 0,
                      0, 0, 0, 0,
                      inatualizacaomonetariaacjud, incustasjudiciais, inhonorariocontratual, inhonorariosadvocaticios,
                      inhonorariosucumbencia, injurosacjud, inmultaacjud, inreservadefesasegurado, invarcambialacjud,
                      vlpagoatualizacaomonetariaacjud, vlpagocustajudicial, vlpagohonorariocontratual, vlpagohonorariosadvocaticios,
                      vlpagosucumbencia, vlpagojurosacjud, vlpagomultaacjud, vlpagoreservadefesasegurado, vlpagovarcambialacjud,
                      true, strindacaojud, cddirec, oDJ.cod_pester, oDJ.tipo_terceiro, out warning);


                if (Session["LIBPARCELAS"] != null)
                {
                    Session.Remove("LIBPARCELAS");
                    dttxtDataVencto.Text = "";
                }

                if (flag)
                {
                    this.Recuperar();
                    TabBase1.BotaoGravarEnabled = false;
                    TabBase1.BotaoExcluirEnabled = false;
                }
            }

            if (warning != null)
            {
                MessageService.Alert(warning, this);
            }
            else if (!flag)
            {
                MessageService.Alert("Cadastrar Nota Fiscal !", this);
            }
            else
            {
                if (flag)
                {
                    AlfaSegNET.Web.UI.WebControls.ToolBar.ToolBarItem itemTB = new AlfaSegNET.Web.UI.WebControls.ToolBar.ToolBarItem();
                    itemTB.ItemTag = "Recuperar";

                    this.TabBase1_ItemClick(itemTB);

                    Session["NROINDENIZACAO"] = txtIndenizacao.Text.Trim();
                }
            }
        }

        protected void chkNaoIncluirReservaDefesaSegurado_Checked_Changed(object sender, EventArgs e)
        {
            if (chkNaoIncluirReservaDefesaSegurado.Checked)
            {
                vlReservaDefesaSeguradoPago.Text = "";
                vlReservaDefesaSeguradoPago.Enabled = false;
            }
            else
                vlReservaDefesaSeguradoPago.Enabled = true;
        }

        protected void chkNaoIncluirHonorariosAdvocaticios_Checked_Changed(object sender, EventArgs e)
        {
            if (chkNaoIncluirHonorariosAdvocaticios.Checked)
            {
                vlHonorariosAdvocaticiosPago.Text = "";
                vlHonorariosAdvocaticiosPago.Enabled = false;
            }
            else
                vlHonorariosAdvocaticiosPago.Enabled = true;
        }

        protected void chkNaoIncluirHonorarioContratual_Checked_Changed(object sender, EventArgs e)
        {
            if (chkNaoIncluirHonorarioContratual.Checked)
            {
                vlHonorarioContratualPago.Text = "";
                vlHonorarioContratualPago.Enabled = false;
            }
            else
                vlHonorarioContratualPago.Enabled = true;
        }

        protected void chkNaoIncluirHonorarioSucumbencia_Checked_Changed(object sender, EventArgs e)
        {
            if (chkNaoIncluirHonorarioSucumbencia.Checked)
            {
                vlHonorarioSucumbenciaPago.Text = "";
                vlHonorarioSucumbenciaPago.Enabled = false;
            }
            else
                vlHonorarioSucumbenciaPago.Enabled = true;
        }

        protected void chkNaoIncluirCustasJudiciais_Checked_Changed(object sender, EventArgs e)
        {
            if (chkNaoIncluirCustasJudiciais.Checked)
            {
                vlCustasJudiciaisPago.Text = "";
                vlCustasJudiciaisPago.Enabled = false;
            }
            else
                vlCustasJudiciaisPago.Enabled = true;
        }

        protected void chkNaoIncluirJurosDeMora_Checked_Changed(object sender, EventArgs e)
        {
            if (chkNaoIncluirJurosDeMora.Checked)
            {
                vlJurosDeMoraPago.Text = "";
                vlJurosDeMoraPago.Enabled = false;
            }
            else
                vlJurosDeMoraPago.Enabled = true;
        }

        protected void chkNaoIncluirMulta_Checked_Changed(object sender, EventArgs e)
        {
            if (chkNaoIncluirMulta.Checked)
            {
                vlMultaPago.Text = "";
                vlMultaPago.Enabled = false;
            }
            else
                vlMultaPago.Enabled = true;
        }

        protected void chkNaoIncluirVariacaoCambial_Checked_Changed(object sender, EventArgs e)
        {
            if (chkNaoIncluirVariacaoCambial.Checked)
            {
                vlVariacaoCambialPago.Text = "";
                vlVariacaoCambialPago.Enabled = false;
            }
            else
                vlVariacaoCambialPago.Enabled = true;
        }

        protected void chkNaoIncluirAtualizacaoMonetaria_Checked_Changed(object sender, EventArgs e)
        {
            if (chkNaoIncluirAtualizacaoMonetaria.Checked)
            {
                vlAtualizacaoMonetariaPago.Text = "";
                vlAtualizacaoMonetariaPago.Enabled = false;
            }
            else
                vlAtualizacaoMonetariaPago.Enabled = true;
        }

        private void LiberarDespesa(int cddesp)
        {
            Fs.Business.Financeiro.DespesaFin oDF = new Fs.Business.Financeiro.DespesaFin();
            Fs.Business.Financeiro.ParcDespFin oPDF = new Fs.Business.Financeiro.ParcDespFin();
            DataSet ds;

            bool flag = Access.ValidateOneItem((DataSet)
                        Session["ALLACCESS"], "Despesa.pbLiberar", Session["_ACT_MODULE"].ToString(),
                        FunctionEnum.EFE);

            if (flag)
            {
                if (cddesp != null && cddesp != 0)
                {
                    oDF.cod_despesa = cddesp;
                    try
                    {
                        oDF.recDespesaFin();
                        flag = false;

                        if (oDF.RecordCount > 0)
                        {
                            if (oDF.situacao_despesa == 0)
                            {
                                oPDF.cod_despesa = oDF.cod_despesa;

                                ds = oPDF.recTodosParcDespFin();
                                int numParc = oPDF.RecordCount;
                                int parcsDesp = oDF.qtde_parcela;
                                if (numParc != parcsDesp)
                                {
                                    flag = false;
                                }
                                else
                                {
                                    flag = true;
                                }

                                decimal totalParcelas = 0;
                                for (int i = 0; i < ds.Tables[0].Rows.Count; i++)
                                {
                                    //Manutenção - 05/10/2004 - Luiz Gimenez Junior
                                    //Valor monetário não pode ser número inteiro
                                    //totalParcelas += Convert.ToInt32(ds.Tables[0].Rows[i]["vlpagar"]);
                                    totalParcelas += Convert.ToDecimal(ds.Tables[0].Rows[i]["vlpagar"]);
                                }
                                if (totalParcelas != oDF.val_pagar)
                                {
                                    flag = false;
                                    MessageService.Alert("Valor Total das Parcelas Incorreto !", this);
                                }
                                else
                                {
                                    flag = true;
                                    oPDF.valor_pagar_despesa = oDF.val_pagar;
                                }

                                if (flag)
                                {
                                    oPDF.usuario = Session["USER"].ToString();
                                    int ret = oPDF.LiberarDespesa();
                                    //Tabela de Retorno
                                    // 0 - Processamento OK
                                    // 1 - Usuário Não Autorizado
                                    // 2 - Sem Aprovadores vinculados ao Orgão Produtor 
                                    // 3 - Erro la Liberação
                                    // 4 - Erro na geração do Lançamento
                                    // 5 - Limite Acumulado Excedido
                                    // 6 - Erro na geração do Movimento
                                    if (ret == 1)
                                    {
                                        MessageService.Alert("Usuário Não Autorizado", this);
                                        return;
                                    }
                                    else if (ret == 2)
                                    {
                                        MessageService.Alert("Sem Aprovadores vinculados ao Órgão Produtor", this);
                                        return;
                                    }
                                    else if (ret == 3)
                                    {
                                        MessageService.Alert("Apresentou erro na Liberação", this);
                                        return;
                                    }
                                    else if (ret == 4)
                                    {
                                        MessageService.Alert("Apresentou erro na Geração do Lançamento", this);
                                        return;
                                    }
                                    else if (ret == 5)
                                    {
                                        MessageService.Alert("Limite Acumulado Excedito", this);
                                        return;
                                    }
                                    else if (ret == 6)
                                    {
                                        MessageService.Alert("Erro na geração do Movimento", this);
                                        return;
                                    }

                                    MessageService.Alert("Despesa Liberada !", this);

                                    oDF.cod_despesa = oPDF.cod_despesa;
                                    oDF.recDespesaFin();
                                }
                            }
                        }
                    }
                    catch
                    {

                    }
                }
            }
            else
            {
                MessageService.Alert("Usuário não Autorizado !", this);
            }
        }

        private void CancelarDespesa(int cddesp)
        {
            Fs.Business.Financeiro.DespesaFin oDF = new Fs.Business.Financeiro.DespesaFin();
            Fs.Business.Financeiro.ParcDespFin oPDF = new Fs.Business.Financeiro.ParcDespFin();
            DataSet ds;

            bool flag = Access.ValidateOneItem((DataSet)
                    Session["ALLACCESS"], "Despesa.pbCancelar", Session["_ACT_MODULE"].ToString(),
                    FunctionEnum.EFE);

            if (flag)
            {

                oDF.cod_despesa = cddesp;
                try
                {
                    oDF.recDespesaFin();

                    if (oDF.RecordCount > 0)
                    {
                        if (oDF.situacao_despesa == 7 || oDF.situacao_despesa == 1)
                        {
                            oPDF.cod_despesa = oDF.cod_despesa;

                            ds = oPDF.recTodosParcDespFin();
                            int numParc = oPDF.RecordCount;
                            int parcsDesp = oDF.qtde_parcela;
                            if (numParc != parcsDesp)
                            {
                                flag = false;
                            }
                            else
                            {
                                flag = true;
                            }

                            int totalParcelas = 0;
                            for (int i = 0; i < ds.Tables[0].Rows.Count; i++)
                            {
                                totalParcelas += Convert.ToInt32(ds.Tables[0].Rows[i]["vlpagar"]);
                            }
                            if (totalParcelas != oDF.val_pagar)
                            {
                                flag = false;
                                MessageService.Alert("Valor Total das Parcelas Incorreto !", this);
                            }
                            else
                            {
                                flag = true;
                                oPDF.valor_pagar_despesa = oDF.val_pagar;
                            }

                            if (flag)
                            {
                                oPDF.CancelarDespesa();
                                MessageService.Alert("Despesa Cancelada !", this);

                                oDF.cod_despesa = oPDF.cod_despesa;
                                oDF.recDespesaFin();
                            }
                        }
                    }
                }
                catch
                {

                }
            }
            else
            {
                MessageService.Alert("Usuário não Autorizado !", this);
            }
        }

        private void ExcluirDespesa(int cddesp)
        {
            if (cddesp != null)
            {
                Fs.Business.Financeiro.DespesaFin oDF =
                    new Fs.Business.Financeiro.DespesaFin();

                Fs.Business.Financeiro.ParcDespFin oPDF =
                    new Fs.Business.Financeiro.ParcDespFin();

                DataSet ds = null;

                oDF.cod_despesa = cddesp;

                oPDF.cod_despesa = cddesp;

                ds = oPDF.recTodosParcDespFin();

                try
                {
                    if (ds != null)
                    {
                        for (int i = 0; i < ds.Tables[0].Rows.Count; i++)
                        {
                            oPDF.cod_parcela = short.Parse(ds.Tables[0].Rows[i]["nrparcela"].ToString());
                            oPDF.data_atualizacao = Convert.ToDateTime(ds.Tables[0].Rows[i]["dtatu"]);
                            oPDF.excParcDespFin();
                        }
                    }

                    oDF.BeginTransaction();
                    //É necessário primeiro reaver o registro para capturar @dtatu
                    oDF.recDespesaFin();
                    oDF.excDespesaFin();
                    oDF.CommitTransaction();

                    MessageService.Alert("Registro Excluído com Sucesso !", this);
                }
                catch
                {

                }
                finally
                {

                }
            }
            else
            {
                MessageService.Alert("Recuperar Despesa !", this);
            }
        }

        #endregion

        #region imbBeneficiario
        protected void imbBeneficiario_Click(object sender, System.Web.UI.ImageClickEventArgs e)
        {
            if (Access.ValidateAccess((DataSet)Session["ALLACCESS"], "FiltroCliente.aspx"))
            {
                string url;
                this.SavePageState();
                if (ddlCobertura.Items.Count > 1)
                    Session["INDENIZACAOCOB"] = ddlCobertura.SelectedIndex;
                if (txtBeneficiario.Text.Trim() != "")
                    url = "FiltroCliente.aspx?type=novinc&idpageret=JuridicoIndenizaDespesa.aspx&idpage=JuridicoIndenizaDespesa.aspx&idtab=&dirpesq=" + txtBeneficiario.Text.Trim().ToUpper() + "&cddirec=" + txtSequencia.Text.Trim() + "&cdpester=" + Request.QueryString["cdpester"] + "&tpter=" + Request.QueryString["tpter"];
                else
                    url = "FiltroCliente.aspx?type=novinc&idpageret=JuridicoIndenizaDespesa.aspx&idpage=JuridicoIndenizaDespesa.aspx&idtab=&cddirec=" + txtSequencia.Text.Trim() + "&cdpester=" + Request.QueryString["cdpester"] + "&tpter=" + Request.QueryString["tpter"];
                Response.Redirect(url);
            }
        }
        #endregion

        #region Load Combox
        private void LoadDllCombo()
        {
            //populate the default ddl properties
            ddlMeioPagto.DataValueField = "cod";
            ddlMeioPagto.DataTextField = "desc";
            ddlMeioPagto.DataSource = this.TabelaMeioPagamento().Tables["MeioPagamentoIndeniz"];
            ddlMeioPagto.DataBind();
            ddlMeioPagto.SelectedValue = "0";

            Fs.Business.Financeiro.Operacao oFO = new Fs.Business.Financeiro.Operacao();
            DataSet ds1, ds3;

            try
            {
                ds1 = oFO.recOperacaoAviso();

                ddlOperacao.DataValueField = oFO.GetPhisicalName("cod_operacao", oFO.GetArray());
                ddlOperacao.DataTextField = oFO.GetPhisicalName("desc_operacao", oFO.GetArray());
                ddlOperacao.DataSource = ds1;
                ddlOperacao.DataBind();
                this.ddlOperacao.SelectedIndex = 0;
            }
            catch { }

            Fs.Business.Sies.ReferMonetaria oRM = new Fs.Business.Sies.ReferMonetaria();

            try
            {
                ds3 = oRM.recReferMonetariaVigente();

                ddlReferencia.DataValueField = oRM.GetPhisicalName("cod_referencia_monetaria", oRM.GetArray());
                ddlReferencia.DataTextField = oRM.GetPhisicalName("nome_referencia_monetaria", oRM.GetArray());
                ddlReferencia.DataSource = ds3;
                ddlReferencia.DataBind();
                PositionList.PositionObjectList(ddlReferencia, "1");
            }
            catch { }
        }
        #endregion

        #region ddlMeioPagto
        protected void ddlMeioPagto_SelectedIndexChanged(object sender, System.EventArgs e)
        {
            if (short.Parse(ddlMeioPagto.SelectedItem.Value) == 2)
            {
                nutxtBanco.ReadOnly = false;
                nutxtAgencia.ReadOnly = false;
                txtContaCorrente.ReadOnly = false;
                txtDigitoAg.ReadOnly = false;
                txtDigitoCC.ReadOnly = false;

                oConsistent.Add(nutxtBanco);
                oConsistent.Add(nutxtAgencia);
                oConsistent.Add(txtContaCorrente);
                oConsistent.Add(txtDigitoCC);

                if (sender != null) nutxtBanco.SetFocus();
            }
            else
            {
                nutxtBanco.Text = "";
                nutxtAgencia.Text = "";
                txtContaCorrente.Text = "";
                txtDigitoAg.Text = "";
                txtDigitoCC.Text = "";

                nutxtBanco.ReadOnly = true;
                nutxtAgencia.ReadOnly = true;
                txtContaCorrente.ReadOnly = true;
                txtDigitoAg.ReadOnly = true;
                txtDigitoCC.ReadOnly = true;

                oConsistent.Remove(nutxtBanco);
                oConsistent.Remove(nutxtAgencia);
                oConsistent.Remove(txtContaCorrente);
                oConsistent.Remove(txtDigitoCC);

                if (sender != null) vltxtIndenizacao.SetFocus();
            }

            if (short.Parse(ddlMeioPagto.SelectedItem.Value) == 4)
            {
                oConsistent.Add(nuNrCodBarras1);
                oConsistent.Add(nuNrCodBarras2);
                oConsistent.Add(nuNrCodBarras3);
                oConsistent.Add(nuNrCodBarras4);
                oConsistent.Add(nuNrCodBarras5);
                oConsistent.Add(nuNrCodBarras6);
                oConsistent.Add(nuNrCodBarras7);
                oConsistent.Add(nuNrCodBarras8);

                nuNrCodBarras1.Visible = true;
                nuNrCodBarras2.Visible = true;
                nuNrCodBarras3.Visible = true;
                nuNrCodBarras4.Visible = true;
                nuNrCodBarras5.Visible = true;
                nuNrCodBarras6.Visible = true;
                nuNrCodBarras7.Visible = true;
                nuNrCodBarras8.Visible = true;
                lblLinhaDigitavel.Visible = true;
            }
            else
            {
                oConsistent.Remove(nuNrCodBarras1);
                oConsistent.Remove(nuNrCodBarras2);
                oConsistent.Remove(nuNrCodBarras3);
                oConsistent.Remove(nuNrCodBarras4);
                oConsistent.Remove(nuNrCodBarras5);
                oConsistent.Remove(nuNrCodBarras6);
                oConsistent.Remove(nuNrCodBarras7);
                oConsistent.Remove(nuNrCodBarras8);

                nuNrCodBarras1.Visible = false;
                nuNrCodBarras2.Visible = false;
                nuNrCodBarras3.Visible = false;
                nuNrCodBarras4.Visible = false;
                nuNrCodBarras5.Visible = false;
                nuNrCodBarras6.Visible = false;
                nuNrCodBarras7.Visible = false;
                nuNrCodBarras8.Visible = false;
                lblLinhaDigitavel.Visible = false;
                nuNrCodBarras1.Text = "";
                nuNrCodBarras2.Text = "";
                nuNrCodBarras3.Text = "";
                nuNrCodBarras4.Text = "";
                nuNrCodBarras5.Text = "";
                nuNrCodBarras6.Text = "";
                nuNrCodBarras7.Text = "";
                nuNrCodBarras8.Text = "";
            }

            if (short.Parse(ddlMeioPagto.SelectedItem.Value) == 1)
            {
                txtObsCheque.Visible = true;
                lblObsCheque.Visible = true;
                oConsistent.Add(txtObsCheque);
            }
            else
            {
                txtObsCheque.Visible = false;
                txtObsCheque.Text = "";
                lblObsCheque.Visible = false;
                oConsistent.Remove(txtObsCheque);
            }
        }
        #endregion

        //#region nutxtParcela
        //protected void nutxtParcela_TextChanged(object sender, System.EventArgs e)
        //{
        //    if (nutxtParcela.Text.Trim() != "")
        //    {
        //        if (nutxtParcela.Text.Trim() == "1")
        //        {
        //            dttxtDataVencto.ReadOnly = false;
        //            dttxtDataVencto.Text = "";
        //            oConsistent.Add(dttxtDataVencto);
        //            dttxtDataVencto.SetFocus();

        //            if (Session["IND_DATVEN"] != null)
        //                dttxtDataVencto.Text = Transformer.CheckValue(Convert.ToDateTime(Session["IND_DATVEN"]));
        //        }
        //        else if (Convert.ToInt16(nutxtParcela.Text.Trim()) > 1)
        //        {
        //            dttxtDataVencto.ReadOnly = true;
        //        }
        //        else if (nutxtParcela.Text.Trim() == "0")
        //        {
        //            MessageService.Alert("Número de Parcelas não pode ser Zero !", this);
        //            nutxtParcela.Text = "";
        //            nutxtParcela.SetFocus();
        //        }
        //    }
        //}
        //#endregion

        #region Kill
        private void Kill()
        {

            Session.Remove("IND_ARRDIS");
            Session.Remove("IND_ARRCDDELETE");
            Session.Remove("IND_DATVEN");
            Session.Remove("ARRIS");
            Session.Remove("INDENIZACAO");
            Session.Remove("GRDSELECTED");
            Session.Remove("IDPESSOA");
            Session.Remove("INDENIZACAOANSWER");
            Session.Remove("INDENIZACAOCOB");
            Session.Remove("INDENIZACAO_SAVE");
            Session.Remove("IND_DATVEN");
            Session.Remove("RAMO");
            Session.Remove("SUBRAMO");
            Session.Remove("ITEM");
            Session.Remove("CDORGAO");
            Session.Remove("TIPOORGAO");

            Session.Remove("cdAviso");
            Session.Remove("cdParte");
            Session.Remove("cdPesTer");
            Session.Remove("tpTer");
            Session.Remove("numSeq");
            Session.Remove("cdOrc");
            Session.Remove("cdCompl");
            Session.Remove("cdorgprt");
            Session.Remove("tporgprt");
            Session.Remove("cdorgprt");
            Session.Remove("vldeduzirimp");
            Session.Remove("vlorcamento");
            Session.Remove("vlorcamentoliq");
            Session.Remove("vlfranquia");

        }
        #endregion

        //#region ddlCobertura
        //protected void ddlCobertura_SelectedIndexChanged(object sender, System.EventArgs e)
        //{
        //    if (txtProtocolo.Text.Trim() != "")
        //    {
        //        Fs.Business.Sinistro.CoberturaSinistro oCS = new Fs.Business.Sinistro.CoberturaSinistro();
        //        oCS.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
        //        oCS.cod_cobertura_sinistro = short.Parse(ddlCobertura.SelectedItem.Value);

        //        try
        //        {
        //            oCS.recCoberturaSinistro();
        //            vltxtValorMaximo.Text = Formatter.FormatCurrency(oCS.val_total_indenizacao).ToString();
        //            vltxtPago.Text = Formatter.FormatCurrency(oCS.val_pago).ToString();
        //        }
        //        catch { }
        //    }
        //}
        //#endregion

        #region ibLimpar
        protected void ibLimpar_Click(object sender, System.Web.UI.ImageClickEventArgs e)
        {
            this.AtualizarControlesParcelas();
        }
        #endregion

        #region DeleteRows
        private void DeleteRows(DataSet ds)
        {
            DataRow[] drc = ds.Tables[0].Select("nmpes is null");

            for (int i = 0; i < drc.Length; i++)
                ds.Tables[0].Rows.Remove(drc[i]);

            drc = null;
        }
        #endregion

        #region CheckVenc
        private bool CheckVenc(DataSet ds)
        {
            DateTime maxpar = Convert.ToDateTime(ds.Tables[0].Compute("max(dtven)", null));

            if (maxpar >= Convert.ToDateTime(dttxtVencimento.Text))
                return false;

            return true;
        }
        #endregion

        #region AddRows
        private void AddRows(DataSet ds)
        {
            DataRow drnew = null;
            bool newrow = false;
            bool flag = false;
            int maxvalidrow = 0;
            ArrayList arrDis = null;
            int i = 0;

            Consistent oCon = new Consistent();

            oCon.Add(dttxtVencimento);
            oCon.Add(vltxtIndenParcela);

            flag = oCon.Consists();

            this.DeleteRows(ds);

            if (ds.Tables[0].Rows.Count == 0)
            {
                flag = true;
                newrow = true;
            }

            if (ds.Tables[0].Rows.Count > 0 && flag)
            {
                if (Session["GRDSELECTED"] == null)
                    flag = this.CheckVenc(ds);
                else
                    flag = true;

                if (!flag)
                {
                    MessageService.Alert("Data de Vencimento Inválida !", this);
                    dttxtVencimento.SetFocus();
                }
            }

            if (flag)
            {

                if (Session["IND_ARRDIS"] == null)
                    arrDis = new ArrayList();
                else
                    arrDis = (ArrayList)Session["IND_ARRDIS"];

                if (Session["GRDSELECTED"] != null)
                {
                    drnew = ds.Tables[0].Rows[Convert.ToInt32(Session["GRDSELECTED"])];
                }
                else
                {
                    newrow = true;
                    object[] obj = new object[ds.Tables[0].Columns.Count];
                    for (i = 0; i < ds.Tables[0].Columns.Count; i++)
                    {
                        if (ds.Tables[0].Rows.Count > 0)
                            obj[i] = ds.Tables[0].Rows[0][i];
                        else
                            obj[i] = DBNull.Value;
                    }

                    ds.Tables[0].Rows.Add(obj);
                    drnew = ds.Tables[0].Rows[ds.Tables[0].Rows.Count - 1];
                }

                drnew.BeginEdit();
                drnew["nmpes"] = txtBeneficiario.Text;
                drnew["cdpes"] = Convert.ToInt32(Session["IDPESSOA"]);
                drnew["dtven"] = dttxtVencimento.Text;
                drnew["dtpagto"] = Fs.Services.Util.Nullable.DbNullDate(txtPagamento.Text);
                if (Convert.ToDateTime(drnew["dtpagto"]) == Fs.Services.Util.Nullable.DbNullDate())
                    drnew["dtpagto"] = DBNull.Value;

                drnew["vlparc"] = vltxtIndenParcela.Text;

                if (vltxtCorrecao.Text.Trim() != "")
                    drnew["vlcorrbencon"] = vltxtCorrecao.Text;
                else
                    drnew["vlcorrbencon"] = "0";

                drnew["stparcela"] = "0";
                drnew["destparcela"] = "Pendente";

                if (Session["GRDSELECTED"] == null)
                    drnew["cdparsin"] = "0";

                drnew.EndEdit();
                drnew.AcceptChanges();

                if (newrow)
                {
                    DataRow[] drc = ds.Tables[0].Select("nmpes is not null");
                    maxvalidrow = drc.Length - 1;
                    drc = null;
                }

                arrDis.Add(maxvalidrow);
                Session["IND_ARRDIS"] = arrDis;

                dgParcelas.DataSource = Paging.BalancePage(ds, dgParcelas.PageSize);
                dgParcelas.DataBind();

                Session["INDENIZACAO"] = ds;
                Session["INDENIZACAOANSWER"] = ds;
                if (Session["GRDSELECTED"] != null)
                    Session.Remove("GRDSELECTED");

                dttxtVencimento.Text = "";
                txtPagamento.Text = "";
                vltxtIndenParcela.Text = "";
                vltxtCorrecao.Text = "";
                dgParcelas.SelectedIndex = -1;

                if (newrow)
                {
                    for (int index = 0; index < arrDis.Count; index++)
                    {
                        Fs.Web.UI.WebControls.CheckBox cb = (Fs.Web.UI.WebControls.CheckBox)
                            dgParcelas.Items[Convert.ToInt32(arrDis[index])]
                            .FindControl("cbDelete");
                        cb.Enabled = false;
                        cb.ToolTip = "Registro não está contido na base de dados ...";
                    }
                }

                dttxtVencimento.SetFocus();
                oCon = null;
            }
        }
        #endregion

        #region CreateDataSet
        private DataSet CreateDataSet(DataSet ds)
        {
            if (ds == null)
            {
                ds = new DataSet();
                ds.Tables.Add();
                ds.Tables[0].Columns.Add("nmpes", Type.GetType("System.String"));
                ds.Tables[0].Columns.Add("cdpes", Type.GetType("System.Int32"));
                ds.Tables[0].Columns.Add("dtven", Type.GetType("System.DateTime"));
                ds.Tables[0].Columns.Add("dtpagto", Type.GetType("System.DateTime"));
                ds.Tables[0].Columns.Add("vlparc", Type.GetType("System.Decimal"));
                ds.Tables[0].Columns.Add("vlcorrbencon", Type.GetType("System.Decimal"));
                ds.Tables[0].Columns.Add("stparcela", Type.GetType("System.Int16"));
                ds.Tables[0].Columns.Add("destparcela", Type.GetType("System.String"));
                ds.Tables[0].Columns.Add("cdparsin", Type.GetType("System.Int16"));

                return ds;
            }
            else
            {
                if (Session["IDPESSOA"] != null && txtProtocolo.Text.Trim() != "" && ddlCobertura.SelectedIndex != -1 && txtIndenizacao.Text.Trim() != "")
                {
                    if (ds == null)
                    {
                        Fs.Business.Sinistro.ParcelaSinistro oPS =
                            new Fs.Business.Sinistro.ParcelaSinistro();

                        oPS.cod_pessoa = Convert.ToInt32(Session["IDPESSOA"]);
                        oPS.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
                        oPS.cod_cobertura_sin = short.Parse(ddlCobertura.SelectedItem.Value);
                        oPS.cod_indenizacao = short.Parse(txtIndenizacao.Text.Trim());

                        try
                        {
                            ds = oPS.recParcelaSinistroIndeniz();
                        }
                        catch
                        {
                        }
                        oPS = null;
                    }
                }
            }



            return ds;
        }
        #endregion

        #region ibGravar
        protected void ibGravar_Click(object sender, System.Web.UI.ImageClickEventArgs e)
        {
            if (this.dttxtVencimento.Text != "" && vltxtIndenParcela.Text != "")
            {
                if (Convert.ToDateTime(dttxtVencimento.Text) < Convert.ToDateTime(Session["DATASISTEMA"]))
                {
                    MessageService.Alert("Data Vencimento deve ser maior que a data do Sistema !", this);
                    return;
                }

                DataSet ds = (DataSet)Session["INDENIZACAO"];
                ds = this.CreateDataSet(ds);
                this.AddRows(ds);
                this.ReloadGridTemplate();
                dgParcelas.CheckValidItems();
                this.AtualizarControlesParcelas();
            }


        }
        #endregion

        private void AtualizarControlesParcelas()
        {
            int intParcelas = 0;
            decimal decTotal = 0;
            System.Web.UI.WebControls.LinkButton lb;
            Fs.Web.UI.WebControls.CheckBox cb;
            for (int i = 0; i < this.dgParcelas.Items.Count; i++)
            {
                if (i == 0)
                {
                    //Mostra a Data de Vencimento da Primeira Parcela
                    lb = (LinkButton)this.dgParcelas.Items[i].FindControl("lbDataVencimento");
                    if (lb.Text.Trim().Length != 0)
                        this.dttxtDataVencto.Text = lb.Text.Trim();
                    else
                        this.dttxtDataVencto.Text = "";
                }
                if (this.dgParcelas.Items[i].Cells[3].Text.Trim() != "&nbsp;")
                {
                    //Desconsidera registros marcados para deleção
                    cb = (Fs.Web.UI.WebControls.CheckBox)this.dgParcelas.Items[i].FindControl("cbDelete");
                    if (!cb.Checked)
                    {
                        //Soma Parcelas e Total
                        intParcelas++;
                        decTotal += decimal.Parse(this.dgParcelas.Items[i].Cells[3].Text.Trim());
                    }
                }
            }
            //Atualiza controles com total de Parcelas e valor de Indenização
            this.vltxtIndenizacao.Text = decTotal.ToString();
        }

        #region dgParcelas
        protected void dgParcelas_SelectedIndexChanged(object sender, System.EventArgs e)
        {
            DataSet ds = (DataSet)Session["INDENIZACAO"];
            DataRow dr = ds.Tables[0].Rows[dgParcelas.SelectedIndex];

            Session["GRDSELECTED"] = dgParcelas.SelectedIndex;

            dttxtVencimento.Text = Transformer.CheckValue(Convert.ToDateTime(dr["dtven"]));
            if (dr["dtpagto"].ToString() != "")
                txtPagamento.Text = Transformer.CheckValue(Convert.ToDateTime(dr["dtpagto"]));
            vltxtIndenParcela.Text = Formatter.FormatCurrency(Convert.ToDecimal(dr["vlparc"])).ToString();
            if (dr["vlcorrbencon"] != System.DBNull.Value)
                vltxtCorrecao.Text = dr["vlcorrbencon"].ToString() == "0" ? "" : Formatter.FormatCurrency(Convert.ToDecimal(dr["vlcorrbencon"])).ToString();

            ds = null;
            dr = null;

            this.StorageGridTemplate();


        }
        #endregion

        #region ReloadGridTemplate
        private void ReloadGridTemplate()
        {
            ArrayList arrList = (ArrayList)Session["IND_ARRCDDELETE"];

            if (arrList != null)
            {
                for (int index = 0; index < arrList.Count; index++)
                {
                    Fs.Web.UI.WebControls.CheckBox cb = (Fs.Web.UI.WebControls.CheckBox)
                        dgParcelas.Items[Convert.ToInt32(arrList[index])]
                        .FindControl("cbDelete");
                    cb.Checked = true;
                }
            }
        }
        #endregion

        #region StorageGridTemplate
        private void StorageGridTemplate()
        {
            ArrayList arrList = new ArrayList();

            for (int index = 0; index < dgParcelas.Items.Count; index++)
            {
                Fs.Web.UI.WebControls.CheckBox cb = (Fs.Web.UI.WebControls.CheckBox)
                    dgParcelas.Items[index].FindControl("cbDelete");
                if (cb.Checked) arrList.Add(index);
            }

            if (arrList.Count > 0)
                Session["IND_ARRCDDELETE"] = arrList;
            else
                Session.Remove("IND_ARRCDDELETE");

            this.AtualizarControlesParcelas();
        }
        #endregion

        #region ReloadPageState
        private void ReloadPageState()
        {
            if (Session["TPSERVICO"] != null)
            {
                ddlTpServico.DataSource = (DataSet)Session["TPSERVICO"];
                ddlTpServico.DataBind();

                ListItem lst = new ListItem(" ", " ");
                ddlTpServico.Items.Insert(0, lst);

                if (Session["DDLTPSERVICO"] != null)
                {
                    PositionList.PositionObjectList(ddlTpServico, Session["DDLTPSERVICO"].ToString());
                    Session.Remove("DDLTPSERVICO");
                }

            }

            DataSet ds = (DataSet)Session["INDENIZACAO_SAVE"];

            if (ds != null)
            {
                AspNetFindControl.ManagementValuesField(this, ds.Tables["Indenizacao_Save"]);
                Session.Remove("INDENIZACAO_SAVE");
            }

            if (Session["CDSOLPAG"] != null)
            {
                this.txtcdsolpag.Text = Session["CDSOLPAG"].ToString().Trim();
                Session.Remove("CDSOLPAG");
            }


        }
        #endregion

        #region SavePageState
        private void SavePageState()
        {
            System.Web.UI.Page[] pages = new System.Web.UI.Page[1];
            pages[0] = this;

            ArrayList arrIdControld = new ArrayList();
            ArrayList arrTables = new ArrayList();

            arrIdControld.Add(Fs.Business.Sinistro.IndenizacaoSinistro.GetIdsDados());
            arrIdControld.Add(Fs.Business.Sinistro.IndenizacaoSinistro.GetIdsObservacoes());
            arrIdControld.Add(Fs.Business.Sinistro.IndenizacaoSinistro.GetIdsParcelas());
            arrIdControld.Add(Fs.Business.Sinistro.IndenizacaoSinistro.GetIdsPrincipal());

            arrTables.Add("Indenizacao_Save");

            Session["INDENIZACAO_SAVE"] = AspNetFindControl.
                GetValuesItemsOtherPage(pages, arrIdControld, arrTables, true);

            if (ddlTpServico.Items.Count != 0)
                Session["DDLTPSERVICO"] = ddlTpServico.SelectedItem.Value;

            Session["CDSOLPAG"] = this.txtcdsolpag.Text.Trim();
        }
        #endregion

        private void HabilitarDespesasJudicial()
        {
            DadosJudiciais oDJ = new DadosJudiciais();
            oDJ.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
            oDJ.cod_direcionamento = short.Parse(txtSequencia.Text.Trim());
            oDJ.cod_pester = string.IsNullOrEmpty(Request.QueryString["cdpester"]) ? -1 : int.Parse(Request.QueryString["cdpester"]);
            oDJ.tipo_terceiro = string.IsNullOrEmpty(Request.QueryString["tpter"]) ? (short)-1 : short.Parse(Request.QueryString["tpter"]);

            oDJ.recDadosJudiciaisTerceiro();

            if (oDJ.RecordCount == 0)
            {
                MessageService.Alert("Não encontrado dados judiciais para este protocolo e sequência!", this);
                return;
            }

            if (oDJ.tipo_status != 1)
            {
                TabBase1.BotaoGravarEnabled = false;
                TabBase1.BotaoExcluirEnabled = false;

                MessageService.Alert("Para fazer pagamentos é necessário ter uma Ação Judicial/Defesa do Segurado Liberada!", this);
            }
            else
            {
                TabBase1.BotaoGravarEnabled = true;
                TabBase1.BotaoExcluirEnabled = true;
            }

            chkNaoIncluirReservaDefesaSegurado.Enabled = false;
            vlReservaDefesaSeguradoPago.Enabled = false;
            chkNaoIncluirHonorariosAdvocaticios.Enabled = false;
            vlHonorariosAdvocaticiosPago.Enabled = false;
            chkNaoIncluirHonorarioContratual.Enabled = false;
            vlHonorarioContratualPago.Enabled = false;
            chkNaoIncluirHonorarioSucumbencia.Enabled = false;
            vlHonorarioSucumbenciaPago.Enabled = false;
            chkNaoIncluirCustasJudiciais.Enabled = false;
            vlCustasJudiciaisPago.Enabled = false;
            chkNaoIncluirVariacaoCambial.Enabled = false;
            vlVariacaoCambialPago.Enabled = false;
            chkNaoIncluirMulta.Enabled = false;
            vlMultaPago.Enabled = false;
            chkNaoIncluirAtualizacaoMonetaria.Enabled = false;
            vlAtualizacaoMonetariaPago.Enabled = false;
            chkNaoIncluirJurosDeMora.Enabled = false;
            vlJurosDeMoraPago.Enabled = false;

            if (oDJ.ind_defesa_segurado == 1)
            {
                chkNaoIncluirReservaDefesaSegurado.Enabled = true;
                vlReservaDefesaSeguradoPago.Enabled = true;
                chkNaoIncluirHonorariosAdvocaticios.Enabled = true;
                vlHonorariosAdvocaticiosPago.Enabled = true;
                vltxtIndenizacao.Enabled = false;
                rblLiquidacao.Enabled = true;
            }
            else
            {
                chkNaoIncluirHonorarioContratual.Enabled = true;
                vlHonorarioContratualPago.Enabled = true;
                chkNaoIncluirHonorarioSucumbencia.Enabled = true;
                vlHonorarioSucumbenciaPago.Enabled = true;
                chkNaoIncluirCustasJudiciais.Enabled = true;
                vlCustasJudiciaisPago.Enabled = true;
                //chkNaoIncluirVariacaoCambial.Enabled = true;
                //vlVariacaoCambialPago.Enabled = true;
                chkNaoIncluirMulta.Enabled = true;
                vlMultaPago.Enabled = true;
                chkNaoIncluirAtualizacaoMonetaria.Enabled = true;
                vlAtualizacaoMonetariaPago.Enabled = true;
                chkNaoIncluirJurosDeMora.Enabled = true;
                vlJurosDeMoraPago.Enabled = true;
                vltxtIndenizacao.Enabled = true;
                rblLiquidacao.Enabled = false;
            }
        }


        #region RecParametros
        private void RecParametros(bool bolRetPesq)
        {
            bool passar = false;
            Fs.Business.Sinistro.IndenizacaoSinistro oIS = new Fs.Business.Sinistro.IndenizacaoSinistro();

            ArrayList arrKey = new ArrayList();

            if (!string.IsNullOrEmpty(Request.QueryString["cdaviso"]) && !string.IsNullOrEmpty(Request.QueryString["cdcobsin"]) && !string.IsNullOrEmpty(Request.QueryString["cdpes"]) &&
                !string.IsNullOrEmpty(Request.QueryString["cdindeniz"]) && bolRetPesq)
            {
                if (Request.QueryString["cdaviso"] != "0")
                {
                    oIS.cod_aviso = int.Parse(Request.QueryString["cdaviso"]);
                    oIS.cod_indenizacao = short.Parse(Request.QueryString["cdindeniz"]);
                    oIS.ind_acao_judicial = (string)Request.QueryString["inacaojud"];
                    oIS.cddirec = short.Parse(Request.QueryString["cddirec"]);
                    oIS.cdpester = string.IsNullOrEmpty(Request.QueryString["cdpester"]) ? -1 : int.Parse(Request.QueryString["cdpester"]);
                    oIS.tpter = string.IsNullOrEmpty(Request.QueryString["tpter"]) ? (short)-1 : short.Parse(Request.QueryString["tpter"]);

                    try
                    {
                        oIS.recIndenizacaoSinistro();
                    }
                    catch { }

                    if (oIS.RecordCount == 0)
                    {
                        passar = false;
                        TabFooter1.Items[Convert.ToInt32(TabFooterIndenixEnum.Liberar)].Enabled = false;
                        MessageService.Alert("Registro não Encontrado !", this);
                        Session.Remove("IND_KEY");
                        Session.Remove("IND_DDL_OPER");
                        Clear();
                    }
                    else
                    {
                        arrKey.Add(oIS.cod_aviso);
                        arrKey.Add(oIS.cod_cobertura_sin);
                        arrKey.Add(oIS.cod_pessoa);
                        arrKey.Add(oIS.cod_indenizacao);
                        this.chkAcaoJudicial.Checked = oIS.ind_acao_judicial == "S";
                        Session["IND_KEY"] = arrKey;
                        Session["IND_DDL_OPER"] = oIS.cod_operacao;
                        passar = true;
                    }
                }
                //Repopula combo quando da chamada para recuperar novo Protocolo
                Session.Remove("PCDCONSEG");
                Session.Remove("PCDEMI");
                Util.MontarDDLAcessoRapido(ref this.QuickAccess1, (DataSet)Session["ALLACCESS"], "Jurídico", this.txtProtocolo.Text, "", "", (Session["TP"] == null || Session["TP"].ToString() == "0"));
                this.QuickAccess1.SelectedIndex = 0;
            }
            else
            {
                oIS.cod_aviso = string.IsNullOrEmpty(txtProtocolo.Text) ? 0 : int.Parse(txtProtocolo.Text.Trim());
                oIS.cddirec = string.IsNullOrEmpty(txtSequencia.Text) ? (short)0 : short.Parse(txtSequencia.Text.Trim());
                oIS.cdpester = string.IsNullOrEmpty(Request.QueryString["cdpester"]) ? -1 : int.Parse(Request.QueryString["cdpester"]);
                oIS.tpter = string.IsNullOrEmpty(Request.QueryString["tpter"]) ? (short)-1 : short.Parse(Request.QueryString["tpter"]);

                DadosJudiciais oDJ = new DadosJudiciais();
                oDJ.cod_aviso = oIS.cod_aviso;
                oDJ.cod_direcionamento = oIS.cddirec;

                oDJ.cod_pester = string.IsNullOrEmpty(Request.QueryString["cdpester"]) ? -1 : int.Parse(Request.QueryString["cdpester"]);
                oDJ.tipo_terceiro = string.IsNullOrEmpty(Request.QueryString["tpter"]) ? (short)-1 : short.Parse(Request.QueryString["tpter"]);

                oDJ.recDadosJudiciaisTerceiro();

                oIS.ind_acao_judicial = oDJ.ind_defesa_segurado == 1 ? "N" : "S";

                if (!string.IsNullOrEmpty(txtIndenizacao.Text))
                {
                    oIS.cod_indenizacao = short.Parse(txtIndenizacao.Text.Trim());

                    try
                    {
                        oIS.recIndenizacaoSinistroAviso();
                    }
                    catch { }

                    if (oIS.RecordCount == 0)
                    {
                        passar = false;
                        TabFooter1.Items[Convert.ToInt32(TabFooterIndenixEnum.Liberar)].Enabled = false;
                        MessageService.Alert("Registro não Encontrado !", this);
                        Session.Remove("IND_KEY");
                        Session.Remove("IND_DDL_OPER");
                        Clear();
                    }
                    else
                    {
                        arrKey.Add(oIS.cod_aviso);
                        arrKey.Add(oIS.cod_cobertura_sin);
                        arrKey.Add(oIS.cod_pessoa);
                        arrKey.Add(oIS.cod_indenizacao);
                        this.chkAcaoJudicial.Checked = oIS.ind_acao_judicial == "S";
                        Session["IND_KEY"] = arrKey;
                        Session["IND_DDL_OPER"] = oIS.cod_operacao;
                        passar = true;
                    }
                }
            }

            if (passar)
            {
                txtSequencia.Enabled = false;
                if (oIS.situacao == 0)
                    txtSituacao.Text = "Pendente";
                else if (oIS.situacao == 1)
                    txtSituacao.Text = "Liberado";
                else if (oIS.situacao == 2)
                    txtSituacao.Text = "Pago";
                else if (oIS.situacao == 5)
                    txtSituacao.Text = "Em Aprovação";
                else
                    txtSituacao.Text = "Cancelado";

                this.GerenciarStatus();

                txtProtocolo.Enabled = false;
                txtSequencia.Enabled = false;
                txtIndenizacao.Enabled = false;
                imbBuscaParam.Enabled = false;

                txtProtocolo.Text = oIS.cod_aviso.ToString();

                txtIndenizacao.Text = oIS.cod_indenizacao.ToString();

                txtSequencia.Text = oIS.cddirec.ToString();

                if (!string.IsNullOrEmpty(oIS.nrcodbarr))
                {
                    nuNrCodBarras1.Text = oIS.nrcodbarr.Substring(0, 5);
                    nuNrCodBarras2.Text = oIS.nrcodbarr.Substring(5, 5);
                    nuNrCodBarras3.Text = oIS.nrcodbarr.Substring(10, 5);
                    nuNrCodBarras4.Text = oIS.nrcodbarr.Substring(15, 6);
                    nuNrCodBarras5.Text = oIS.nrcodbarr.Substring(21, 5);
                    nuNrCodBarras6.Text = oIS.nrcodbarr.Substring(26, 6);
                    nuNrCodBarras7.Text = oIS.nrcodbarr.Substring(32, 1);
                    nuNrCodBarras8.Text = oIS.nrcodbarr.Substring(33, (oIS.nrcodbarr.Length == 48 ? 15 : 14));
                }

                txtObsCheque.Text = oIS.desc_obs;

                txtObs.Text = oIS.obs_2;

                int meiopagamento = oIS.tipo_docto_pagto == 5 ? 2 : oIS.tipo_docto_pagto;

                PositionList.PositionObjectList(ddlReferencia, oIS.cod_referencia_monetaria.ToString());
                PositionList.PositionObjectList(ddlOperacao, oIS.cod_operacao.ToString());
                PositionList.PositionObjectList(ddlMeioPagto, meiopagamento.ToString());
                this.ddlMeioPagto_SelectedIndexChanged(null, null);

                Fs.Business.Sies.Pessoa oPP = new Fs.Business.Sies.Pessoa();

                oPP.cod_pessoa = oIS.cod_pessoa;
                Session["IDPESSOA"] = oIS.cod_pessoa;

                this.PopulaTipoServico();

                if (oIS.cod_tipo_pessoa != -1)
                    PositionList.PositionObjectList(ddlTpServico, oIS.cod_tipo_pessoa.ToString().Trim());
                else
                    ddlTpServico.SelectedIndex = 0;

                try
                {
                    oPP.recPessoa();
                }
                catch { }

                txtBeneficiario.Text = oPP.nome_pessoa;
                Session["CGCCPFPESSOA"] = oPP.num_cgccpf;
                oPP = null;
                if (Convert.ToDateTime(oIS.data_liberacao) == Convert.ToDateTime("01/01/1901"))
                    txtLiberacao.Text = "";
                else
                    txtLiberacao.Text = Formatter.Format(oIS.data_liberacao).ToString();

                RecProtocolo();
                PositionList.PositionObjectList(ddlCobertura, oIS.cod_cobertura_sin.ToString());
                //ddlCobertura_SelectedIndexChanged(null, null);
                vltxtIndenizacao.Text = Formatter.FormatCurrency(oIS.vlpagoacao).ToString();

                if (oIS.perc_participacao == 2)
                {
                    rblLiquidacao.Items[0].Selected = true;
                    rblLiquidacao.Items[1].Selected = false;
                }
                else
                {
                    rblLiquidacao.Items[1].Selected = true;
                    rblLiquidacao.Items[0].Selected = false;
                }
                if (oIS.cod_banco != 0)
                    nutxtBanco.Text = oIS.cod_banco.ToString();
                if (oIS.num_conta_corrente != null)
                    txtContaCorrente.Text = oIS.num_conta_corrente.ToString();
                if (oIS.cod_agencia != 0)
                    nutxtAgencia.Text = oIS.cod_agencia.ToString();
                if (oIS.digito_agencia != null)
                    txtDigitoAg.Text = oIS.digito_agencia.ToString();
                if (oIS.digito_conta_corrente != null)
                    txtDigitoCC.Text = oIS.digito_conta_corrente.ToString();
                txtSolicitacao.Text = Formatter.Format(oIS.data_geracao).ToString();
                if (oIS.nro_nota_fiscal != 0)
                    txtNroNF.Text = oIS.nro_nota_fiscal.ToString();
                if (oIS.serie_nota_fiscal != null)
                    txtSerieNF.Text = oIS.serie_nota_fiscal.ToString();
                if (oIS.nro_nota_fiscal != 0 && oIS.serie_nota_fiscal != null && Session["IDPESSOA"] != null)
                    this.ImageButton1_Click(null, null);

                //Verifica se são despesas referentes a ação judicial ou defesa do segurado
                HabilitarDespesasJudicial();

                chkNaoIncluirAtualizacaoMonetaria.Checked = oIS.inatualizacaomonetariaacjud == 1 ? true : false;
                chkNaoIncluirCustasJudiciais.Checked = oIS.incustasjudiciais == 1 ? true : false;
                chkNaoIncluirHonorarioContratual.Checked = oIS.inhonorariocontratual == 1 ? true : false;
                chkNaoIncluirHonorariosAdvocaticios.Checked = oIS.inhonorariosadvocaticios == 1 ? true : false;
                chkNaoIncluirHonorarioSucumbencia.Checked = oIS.inhonorariosucumbencia == 1 ? true : false;
                chkNaoIncluirJurosDeMora.Checked = oIS.injurosacjud == 1 ? true : false;
                chkNaoIncluirMulta.Checked = oIS.inmultaacjud == 1 ? true : false;
                chkNaoIncluirReservaDefesaSegurado.Checked = oIS.inreservadefesasegurado == 1 ? true : false;
                chkNaoIncluirVariacaoCambial.Checked = oIS.invarcambialacjud == 1 ? true : false;

                if (
                    chkNaoIncluirAtualizacaoMonetaria.Checked &&
                    chkNaoIncluirCustasJudiciais.Checked &&
                    chkNaoIncluirHonorarioContratual.Checked &&
                    chkNaoIncluirHonorariosAdvocaticios.Checked &&
                    chkNaoIncluirHonorarioSucumbencia.Checked &&
                    chkNaoIncluirJurosDeMora.Checked &&
                    chkNaoIncluirMulta.Checked &&
                    chkNaoIncluirReservaDefesaSegurado.Checked &&
                    chkNaoIncluirVariacaoCambial.Checked
                    )
                    chkNaoIncluirDespesas.Checked = true;
                else
                    chkNaoIncluirDespesas.Checked = false;


                if (oIS.inatualizacaomonetariaacjud == 1)
                {
                    vlAtualizacaoMonetariaPago.Text = "";
                    vlAtualizacaoMonetariaPago.Enabled = false;
                }
                else
                    vlAtualizacaoMonetariaPago.Text = Formatter.FormatCurrency(oIS.vlpagoatualizacaomonetariaacjud).ToString();

                if (oIS.incustasjudiciais == 1)
                {
                    vlCustasJudiciaisPago.Text = "";
                    vlCustasJudiciaisPago.Enabled = false;
                }
                else
                    vlCustasJudiciaisPago.Text = Formatter.FormatCurrency(oIS.vlpagocustajudicial).ToString();

                if (oIS.inhonorariocontratual == 1)
                {
                    vlHonorarioContratualPago.Text = "";
                    vlHonorarioContratualPago.Enabled = false;
                }
                else
                    vlHonorarioContratualPago.Text = Formatter.FormatCurrency(oIS.vlpagohonorariocontratual).ToString();

                if (oIS.inhonorariosadvocaticios == 1)
                {
                    vlHonorariosAdvocaticiosPago.Text = "";
                    vlHonorariosAdvocaticiosPago.Enabled = false;
                }
                else
                    vlHonorariosAdvocaticiosPago.Text = Formatter.FormatCurrency(oIS.vlpagohonorariosadvocaticios).ToString();

                if (oIS.injurosacjud == 1)
                {
                    vlJurosDeMoraPago.Text = "";
                    vlJurosDeMoraPago.Enabled = false;
                }
                else
                    vlJurosDeMoraPago.Text = Formatter.FormatCurrency(oIS.vlpagojurosacjud).ToString();

                if (oIS.inmultaacjud == 1)
                {
                    vlMultaPago.Text = "";
                    vlMultaPago.Enabled = false;
                }
                else
                    vlMultaPago.Text = Formatter.FormatCurrency(oIS.vlpagomultaacjud).ToString();

                if (oIS.inreservadefesasegurado == 1)
                {
                    vlReservaDefesaSeguradoPago.Text = "";
                    vlReservaDefesaSeguradoPago.Enabled = false;
                }
                else
                    vlReservaDefesaSeguradoPago.Text = Formatter.FormatCurrency(oIS.vlpagoreservadefesasegurado).ToString();

                if (oIS.inhonorariosucumbencia == 1)
                {
                    vlHonorarioSucumbenciaPago.Text = "";
                    vlHonorarioSucumbenciaPago.Enabled = false;
                }
                else
                    vlHonorarioSucumbenciaPago.Text = Formatter.FormatCurrency(oIS.vlpagosucumbencia).ToString();

                if (oIS.invarcambialacjud == 1)
                {
                    vlVariacaoCambialPago.Text = "";
                    vlVariacaoCambialPago.Enabled = false;
                }
                else
                    vlVariacaoCambialPago.Text = Formatter.FormatCurrency(oIS.vlpagovarcambialacjud).ToString();

                Session["ICDAVISO"] = oIS.cod_aviso;
                Session["ICDINDENIZ"] = oIS.cod_indenizacao;
                Session["VLTXTINDENIZACAO"] = oIS.vlpagoacao;

                DataSet ds1;

                Fs.Business.Sinistro.ParcelaSinistro oPS = new Fs.Business.Sinistro.ParcelaSinistro();

                Session["IDPESSOA"] = oIS.cod_pessoa;
                oPS.cod_pessoa = oIS.cod_pessoa;
                oPS.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
                oPS.cod_cobertura_sin = short.Parse(ddlCobertura.SelectedItem.Value);
                oPS.cod_indenizacao = short.Parse(txtIndenizacao.Text.Trim());


                try
                {
                    ds1 = oPS.recParcelaSinistroIndenizAviso();

                    Session["INDENIZACAO"] = ds1;
                    Session["INDENIZACAOANSWER"] = ds1;

                    if (oIS.qtde_parcelas == 1)
                    {
                        dttxtDataVencto.Text = Transformer.CheckValue(oPS.data_vencimento);
                        Session["IND_DATVEN"] = oPS.data_vencimento;
                    }
                    else
                    {
                        dttxtDataVencto.Text = Formatter.Format(oIS.data_referencia).ToString();
                        Session["LIBPARCELAS"] = ds1;
                    }

                    ds1 = null;
                    oPS = null;

                    oIS = null;
                }
                catch { }
            }
        }
        #endregion

        #region Protocolo
        private void RecProtocolo()
        {
            Consistent oCon = new Consistent();

            oCon.Add(txtProtocolo);
            oCon.Add(txtSequencia);

            if (oCon.Consists())
            {
                Fs.Data.Sinistro.DadosJudiciais oDJ = new Fs.Data.Sinistro.DadosJudiciais();

                oDJ.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
                oDJ.cod_direcionamento = short.Parse(txtSequencia.Text.Trim());
                oDJ.cod_pester = string.IsNullOrEmpty(Request.QueryString["cdpester"]) ? -1 : int.Parse(Request.QueryString["cdpester"]);
                oDJ.tipo_terceiro = string.IsNullOrEmpty(Request.QueryString["tpter"]) ? (short)-1 : short.Parse(Request.QueryString["tpter"]);

                oDJ.recDadosJudiciaisTerceiro();

                if (oDJ.RecordCount == 0)
                    MessageService.Alert("Ação Judicial ou Defesa do segurado não encontrado para o protocolo e sequência informados!", this);
                else
                    vltxtValorMaximo.Text = Formatter.FormatCurrency(oDJ.valor_estimativa);

                Fs.Business.Sinistro.CoberturaSinistro oCS = new CoberturaSinistro();

                DataSet ds2;
                oCS.cod_aviso = Convert.ToInt32(txtProtocolo.Text.Trim());
                try
                {
                    ds2 = oCS.recSinistroAvisoData();

                    if (oCS.RecordCount != 0)
                    {
                        ddlCobertura.DataValueField = oCS.GetPhisicalName("cod_cobertura_sinistro", oCS.GetArray());
                        ddlCobertura.DataTextField = oCS.GetPhisicalName("nome_desc_cobertura", oCS.GetArray());
                        ddlCobertura.DataSource = ds2;
                        ddlCobertura.DataBind();

                        Fs.Business.Sinistro.AvisoSinistro oAS = new Fs.Business.Sinistro.AvisoSinistro();
                        oAS.cod_aviso = Convert.ToInt32(txtProtocolo.Text.Trim());

                        oAS.recAvisoSinistro();
                        DateTime DataSinistro = oAS.data_sinistro;
                        this.chkAcaoJudicial.Enabled = oAS.ind_acao_judicial.Trim() == "S";

                        int Item = oCS.cod_item_seguro;
                        int Conseg = oCS.cod_contrato_seguro;
                        Session["RAMO"] = oCS.cod_ramo_seguro;
                        Session["SUBRAMO"] = oCS.cod_sub_ramo;

                        oCS.cod_cobertura_sinistro = short.Parse(ddlCobertura.SelectedItem.Value);
                        oCS.recCoberturaSinistro();

                        Fs.Business.Sinistro.ComunicUsuario oCU = new Fs.Business.Sinistro.ComunicUsuario();

                        oCU.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
                        oCU.tipo_usuario = 1; //Analista

                        try { oCU.recOrgaoAnalistaSinistro(); }
                        catch { }

                        if (oCU.RecordCount != 0)
                        {
                            if (oCU.cod_orgao_produtor == 0)
                            {
                                oCU.tipo_usuario = 3; //Perito
                                try { oCU.recOrgaoAnalistaSinistro(); }
                                catch { }
                            }

                            if (oCU.cod_orgao_produtor != 0)
                            {
                                Session["CDORGAO"] = oCU.cod_orgao_produtor;
                                Session["TIPOORGAO"] = oCU.tipo_orgao_produtor;
                            }
                            else
                            {
                                Session["CDORGAO"] = null;
                                Session["TIPOORGAO"] = null;
                                MessageService.Alert("Orgão Produtor não Cadastrado !", this);
                            }
                        }
                        else
                        {
                            Session["CDORGAO"] = null;
                            Session["TIPOORGAO"] = null;
                            MessageService.Alert("Orgão Produtor não Cadastrado !", this);
                        }
                        txtIndenizacao.SetFocus();

                        //recupera as imagens anexo 
                        RecuperarImagem();

                        oCS.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
                        oCS.cod_direcionamento = string.IsNullOrEmpty(txtSequencia.Text) ? (short)0 : short.Parse(txtSequencia.Text.Trim());
                        oCS.cod_prestador = string.IsNullOrEmpty(Request.QueryString["cdpester"]) ? -1 : int.Parse(Request.QueryString["cdpester"]);
                        oCS.tipo_terceiro = string.IsNullOrEmpty(Request.QueryString["tpter"]) ? (short)-1 : short.Parse(Request.QueryString["tpter"]);

                        vltxtPago.Text = Formatter.FormatCurrency(oCS.recPagoCoberturaSinistro());
                        txtProtocolo.Enabled = false;
                        txtSequencia.Enabled = false;
                        imbBuscaParam.Enabled = false;
                        HabilitarDespesasJudicial();
                    }
                    else
                    {
                        MessageService.Alert("Cobertura(s) não Encontrada(s) !", this);
                        txtIndenizacao.SetFocus();
                    }
                }
                catch (Exception error)
                {
                    MessageService.Alert("Operação não Efetuada ! Contate Sistemas.", this);
                }
            }
            else
            {
                txtProtocolo.SetFocus();
            }


        }
        #endregion

        protected void chkNaoIncluirDespesas_Checked_Changed(object sender, EventArgs e)
        {
            bool CheckNaoIncluir = false, HabilitaValorDespesa = true;

            if (chkNaoIncluirDespesas.Checked)
            {
                CheckNaoIncluir = true;
                HabilitaValorDespesa = false;
            }

            chkNaoIncluirReservaDefesaSegurado.Checked = CheckNaoIncluir;
            chkNaoIncluirAtualizacaoMonetaria.Checked = CheckNaoIncluir;
            chkNaoIncluirCustasJudiciais.Checked = CheckNaoIncluir;
            chkNaoIncluirHonorarioContratual.Checked = CheckNaoIncluir;
            chkNaoIncluirHonorariosAdvocaticios.Checked = CheckNaoIncluir;
            chkNaoIncluirHonorarioSucumbencia.Checked = CheckNaoIncluir;
            chkNaoIncluirJurosDeMora.Checked = CheckNaoIncluir;
            chkNaoIncluirMulta.Checked = CheckNaoIncluir;
            chkNaoIncluirVariacaoCambial.Checked = CheckNaoIncluir;

            vlReservaDefesaSeguradoPago.Enabled = HabilitaValorDespesa;
            vlHonorariosAdvocaticiosPago.Enabled = HabilitaValorDespesa;
            vlHonorarioContratualPago.Enabled = HabilitaValorDespesa;
            vlHonorarioSucumbenciaPago.Enabled = HabilitaValorDespesa;
            vlCustasJudiciaisPago.Enabled = HabilitaValorDespesa;
            vlJurosDeMoraPago.Enabled = HabilitaValorDespesa;
            vlMultaPago.Enabled = HabilitaValorDespesa;
            //vlVariacaoCambialPago.Enabled = HabilitaValorDespesa;
            vlAtualizacaoMonetariaPago.Enabled = HabilitaValorDespesa;

            if (!HabilitaValorDespesa)
            {
                vlReservaDefesaSeguradoPago.Text = "";
                vlHonorariosAdvocaticiosPago.Text = "";
                vlHonorarioContratualPago.Text = "";
                vlHonorarioSucumbenciaPago.Text = "";
                vlCustasJudiciaisPago.Text = "";
                vlJurosDeMoraPago.Text = "";
                vlMultaPago.Text = "";
                vlVariacaoCambialPago.Text = "";
                vlAtualizacaoMonetariaPago.Text = "";
            }
        }

        #region Recuperar
        private void Recuperar()
        {
            #region Recuperação
            Consistent oCon = new Consistent();

            oCon.Add(txtProtocolo);
            oCon.Add(txtSequencia);
            oCon.Add(txtIndenizacao);

            if (oCon.Consists())
            {
                //Consiste se terceiro tem domínio sobre o Aviso
                if (Session["GLBCDPES"] != null && Session["GLBCDPES"].ToString().Trim() != "0")
                {
                    AvisoSinistro oAS = new AvisoSinistro();
                    if (!oAS.recDominioProcesso(int.Parse(this.txtProtocolo.Text.Trim()),
                        int.Parse(Session["GLBCDPES"].ToString())))
                    {
                        MessageService.Alert("Processo Inexistente em sua Carteira de Clientes!", this);
                        return;
                    }
                }

                oConsistent.Reverse();
                oCon.Reverse();
                RecParametros(false);

                //Repopula combo quando da chamada para recuperar novo Protocolo

                Session.Remove("PCDCONSEG");
                Session.Remove("PCDEMI");
                Util.MontarDDLAcessoRapido(ref this.QuickAccess1, (DataSet)Session["ALLACCESS"], "Jurídico", this.txtProtocolo.Text, "", "", (Session["TP"] == null || Session["TP"].ToString() == "0"));
                this.QuickAccess1.SelectedIndex = 0;
            }
            #endregion
        }
        #endregion

        #region Clear
        private void Clear()
        {
            oClean.Clear();
            ddlCobertura.Items.Clear();
            PositionList.PositionObjectList(ddlReferencia, "1");
            PositionList.PositionObjectList(ddlMeioPagto, "1");

            this.ddlTpServico.Items.Clear();
            this.ddlTpServico.SelectedIndex = -1;
            this.ddlTpServico.SelectedValue = null;
            this.ddlTpServico.ClearSelection();

            rblLiquidacao.Items[1].Selected = true;
            Session["Indenizacao"] = null;
            txtProtocolo.SetFocus();

        }
        #endregion

        #region btnNotaFiscal
        protected void btnNotaFiscal_Click(object sender, System.EventArgs e)
        {
            if (Access.ValidateAccess((DataSet)Session["ALLACCESS"], "NotaFiscal.aspx"))
            {
                if (Session["IDPESSOA"] != null && txtBeneficiario.Text.Trim() != "")
                {
                    this.SavePageState();
                    if (ddlCobertura.Items.Count > 1)
                        Session["INDENIZACAOCOB"] = ddlCobertura.SelectedIndex;
                    if (this.ddlTpServico.Items.Count > 1)
                        Session["DDLTPSERVICO"] = this.ddlTpServico.SelectedIndex;

                    string url = "NotaFiscal.aspx?flagvoltar=true&idpes=" + Session["IDPESSOA"].ToString() +
                        "&nmpes=" + txtBeneficiario.Text.Trim() +
                        "&numnota=" + txtNroNF.Text.Trim() +
                        "&serienota=" + txtSerieNF.Text.Trim() + "&valnota=" + txtValorNF.Text.Trim();
                    Response.Redirect(url);
                }
                else
                {
                    MessageService.Alert("Informe Beneficiário !", this);
                }
            }


        }
        #endregion

        #region Método Privados

        private void OpenModal(bool value)
        {
            ClientScript.RegisterStartupScript(this.GetType(), "key", "launchModal();", value);
        }

        private void PopulaTipoServico()
        {
            Fs.Business.Sies.TipoPapelPessoa oTPP = new Fs.Business.Sies.TipoPapelPessoa();
            oTPP.ReferencePage = this;
            oTPP.cod_pessoa = int.Parse(Session["IDPESSOA"].ToString());

            DataSet ds = oTPP.recTipoPapelPessoaPorPessoa();
            Session["TPSERVICO"] = ds;
            ddlTpServico.Items.Clear();
            ddlTpServico.SelectedIndex = -1;
            ddlTpServico.SelectedValue = null;
            ddlTpServico.ClearSelection();
            ddlTpServico.DataSource = ds;
            ddlTpServico.DataBind();

            ListItem lst2 = new ListItem(" ", " ");
            ddlTpServico.Items.Insert(0, lst2);

            if (ddlTpServico.Items.Count == 2)
                ddlTpServico.SelectedIndex = 1;
            else
                ddlTpServico.SelectedIndex = 0;
        }

        private void PopulaCC()
        {
            if (Session["IDPESSOA"] == null)
                return;

            try
            {
                Fs.Business.Sies.ContaPessoa oCP = new Fs.Business.Sies.ContaPessoa();
                oCP.codigo_pessoa = int.Parse(Session["IDPESSOA"].ToString().Trim());
                DataSet ds = oCP.recContaPessoaTipo(2); //2 - Crédito

                if (oCP.RecordCount != 0)
                {
                    this.nutxtBanco.Text = ds.Tables[0].Rows[0]["cdbco"].ToString().Trim();
                    this.nutxtAgencia.Text = ds.Tables[0].Rows[0]["cdagn"].ToString().Trim();

                    if (ds.Tables[0].Rows[0]["dgtagn"] != System.DBNull.Value)
                        this.txtDigitoAg.Text = ds.Tables[0].Rows[0]["dgtagn"].ToString().Trim();
                    else
                        this.txtDigitoAg.Text = "";

                    this.txtContaCorrente.Text = ds.Tables[0].Rows[0]["nrctaccr"].ToString().Trim();

                    if (ds.Tables[0].Rows[0]["dgtctaccr"] != System.DBNull.Value)
                        this.txtDigitoCC.Text = ds.Tables[0].Rows[0]["dgtctaccr"].ToString().Trim();
                    else
                        this.txtDigitoCC.Text = "";

                    this.ddlMeioPagto.SelectedIndex = 2; //Crédito em C/C
                    this.ddlMeioPagto_SelectedIndexChanged(null, null);
                }
            }
            catch { }
        }

        protected void imbBuscaParam_Click(object sender, ImageClickEventArgs e)
        {
            try
            {
                Consistent oCon = new Consistent();
                oCon.Add(txtProtocolo);
                oCon.Add(txtSequencia);

                if (oCon.Consists())
                {
                    System.Text.StringBuilder sb = new System.Text.StringBuilder();
                    sb.Append("PesquisaJuridico.aspx?");
                    sb.Append("&cdaviso=" + txtProtocolo.Text.Trim());
                    sb.Append("&cddirec=" + txtSequencia.Text.Trim());
                    sb.Append("&pageback=JuridicoIndenizaDespesa.aspx");

                    Response.Redirect(sb.ToString());
                }
            }
            catch (Exception error)
            {
                MessageService.Alert("Operação não Efetuada ! Contate Sistemas.", this);
            }
        }

        //protected void imbBuscaParam_Click(object sender, System.Web.UI.ImageClickEventArgs e)
        //{
        //    Consistent oCon = new Consistent();
        //    oCon.Add(txtProtocolo);
        //    oCon.Add(txtSequencia);

        //    if (oCon.Consists())
        //    {
        //        int Protocolo = int.Parse(txtProtocolo.Text.Trim());
        //        int Sequencia = int.Parse(txtSequencia.Text.Trim());
        //        oClean.Clear();
        //        ddlCobertura.Items.Clear();

        //        txtProtocolo.Text = Protocolo.ToString();
        //        txtSequencia.Text = Sequencia.ToString();

        //        HabilitarDespesasJudicial();

        //        RecProtocolo();
        //        txtIndenizacao.SetFocus();

        //        if (txtSituacao.Text == "Pendente")
        //        {
        //            if (ddlAnexos.Items.Count > 0)
        //                PModalDevolver.Visible = true;
        //        }

        //        txtProtocolo.Enabled = false;
        //        txtSequencia.Enabled = false;
        //        txtIndenizacao.Enabled = false;
        //        imbBuscaParam.Enabled = false;

        //        this.ddlMeioPagto_SelectedIndexChanged(null, null);
        //    }
        //    else
        //        txtProtocolo.SetFocus();

        //    PositionList.PositionObjectList(ddlReferencia, "1");
        //}

        protected void ImageButton1_Click(object sender, System.Web.UI.ImageClickEventArgs e)
        {
            if (txtNroNF.Text.Trim() == "" && txtSerieNF.Text.Trim() != "")
            {
                MessageService.Alert("Digitar Número da Nota para Pesquisar !", this);
                txtNroNF.SetFocus();
            }
            else if (txtNroNF.Text.Trim() != "" && txtSerieNF.Text.Trim() == "")
            {
                MessageService.Alert("Digitar Série da Nota para Pesquisar !", this);
                txtSerieNF.SetFocus();
            }
            else if (txtNroNF.Text.Trim() == "" && txtSerieNF.Text.Trim() == "")
            {
                txtNroNF.SetFocus();
            }
            else
            {
                if (Session["IDPESSOA"] != null)
                {
                    Fs.Business.Financeiro.NotaFiscal oNF = new Fs.Business.Financeiro.NotaFiscal();
                    oNF.cod_pessoa = Convert.ToInt32(Session["IDPESSOA"]);
                    oNF.num_nota_fiscal = int.Parse(txtNroNF.Text);
                    oNF.sigla_serie_nota_fiscal = txtSerieNF.Text.Trim();

                    try { oNF.recNotaFiscal(); }
                    catch { }

                    if (oNF.RecordCount != 0)
                        txtValorNF.Text = Formatter.FormatCurrency(oNF.val_nota_fiscal);
                    else
                    {
                        MessageService.Alert("Registro Não Encontrado!", this);
                        txtNroNF.SetFocus();
                    }
                }
                else
                {
                    MessageService.Alert("Informe o Beneficiário !", this);
                }
            }
        }

        private void GerenciarStatus()
        {
            if (Session["LOG_CDAUX"] != null)
            {
                TabFooter1.Items[Convert.ToInt32(TabFooterIndenixEnum.Liberar)].Enabled = false;
                TabBase1.BotaoGravarEnabled = false;
                TabBase1.BotaoExcluirEnabled = false;
                return;
            }

            switch (this.txtSituacao.Text.Trim())
            {
                case "Pendente":
                    TabFooter1.Items[Convert.ToInt32(TabFooterIndenixEnum.Liberar)].Enabled = true;

                    break;

                case "Liberado":
                    TabFooter1.Items[Convert.ToInt32(TabFooterIndenixEnum.Liberar)].Enabled = false;

                    TabBase1.BotaoGravarEnabled = false;
                    TabBase1.BotaoExcluirEnabled = false;
                    break;

                case "Pago":
                    TabFooter1.Items[Convert.ToInt32(TabFooterIndenixEnum.Liberar)].Enabled = false;
                    TabBase1.BotaoGravarEnabled = false;
                    TabBase1.BotaoExcluirEnabled = false;
                    break;

                case "Em Aprovação":
                    TabFooter1.Items[Convert.ToInt32(TabFooterIndenixEnum.Liberar)].Enabled = true;
                    TabBase1.BotaoGravarEnabled = false;
                    TabBase1.BotaoExcluirEnabled = true;
                    break;

                case "Cancelado":
                    TabFooter1.Items[Convert.ToInt32(TabFooterIndenixEnum.Liberar)].Enabled = false;
                    TabBase1.BotaoGravarEnabled = false;
                    TabBase1.BotaoExcluirEnabled = false;
                    break;

                default:
                    TabFooter1.Items[Convert.ToInt32(TabFooterIndenixEnum.Liberar)].Enabled = false;
                    TabBase1.BotaoExcluirEnabled = false;
                    break;
            }
        }

        //Número de linhas preenchidas da grid (indiferentemente se será deletada ou não);
        private int TotalRegistrosEmParcelas()
        {
            int intRegistros = 0;
            for (int i = 0; i < this.dgParcelas.Items.Count; i++)
            {
                if (this.dgParcelas.Items[i].Cells[3].Text.Trim() != "&nbsp;")
                    intRegistros++;
            }
            return intRegistros;
        }

        protected void imgAtalho_Click(object sender, System.Web.UI.ImageClickEventArgs e)
        {
            if (this.QuickAccess1.SelectedIndex != 0)
                Response.Redirect(QuickAccess1.SelectedValue, false);
        }

        private void RecuperarSolObs(int cdaviso, short cdsolpag)
        {
            SolicitaPagamento oSol = new SolicitaPagamento();
            oSol.cod_aviso = cdaviso;
            oSol.cod_solpag = cdsolpag;
            oSol.recSolicitaPagamento();

            if (oSol.RecordCount > 0)
                this.txtObservacao.Text = oSol.obs;
        }

        private DataSet TabelaMeioPagamento()
        {
            DataSet ds = new DataSet();
            ds.Tables.Add("MeioPagamentoIndeniz");
            ds.Tables[0].Columns.Add("cod", Type.GetType("System.Int16"));
            ds.Tables[0].Columns.Add("desc", Type.GetType("System.String"));

            object[] obj = new object[2];
            obj[0] = 0;
            obj[1] = "Selecionar";
            ds.Tables[0].Rows.Add(obj);
            obj[0] = 1;
            obj[1] = "Cheque";
            ds.Tables[0].Rows.Add(obj);
            obj[0] = 2;
            obj[1] = "Crédito em C/C";
            ds.Tables[0].Rows.Add(obj);
            obj[0] = 7;
            obj[1] = "Borderô";
            ds.Tables[0].Rows.Add(obj);
            obj[0] = 4;
            obj[1] = "Boleto Bancário";
            ds.Tables[0].Rows.Add(obj);
            return ds;
        }

        #endregion

        protected void TabFooter1_MenuItemClick(object sender, MenuEventArgs e)
        {
            string warning = string.Empty;
            bool flag = false;
            bool flagModal = false;

            try
            {
                hdfTabFooterSelectedIndex.Value = e.Item.Value;

                var ICDAVISO = Session["ICDAVISO"];
                var ICDINDENIZ = Session["ICDINDENIZ"];

                if (Convert.ToInt32(e.Item.Value) == (int)TabFooterIndenixEnum.Liberar
                    || Convert.ToInt32(hdfTabFooterSelectedIndex.Value) == (int)TabFooterIndenixEnum.Liberar)
                {
                    if (!Access.ValidateOneItem((DataSet)Session["ALLACCESS"],
                        "JudIndeniza.pbLiberar", Session["_ACT_MODULE"].ToString(), FunctionEnum.EFE))
                    {
                        MessageService.Alert("Usuário não Autorizado.", this);
                        return;
                    }

                    Fs.Business.Sinistro.IndenizacaoSinistro oIS = new Fs.Business.Sinistro.IndenizacaoSinistro();
                    oIS.ReferencePage = this;

                    if (Session["LIBPARCELAS"] != null)
                    {
                        DataSet dsPar = (DataSet)Session["LIBPARCELAS"];
                        dttxtDataVencto.Text = Transformer.CheckValue(Convert.ToDateTime(dsPar.Tables[0].Rows[0]["dtven"]));
                        dsPar = null;
                    }

                    if (ValidarLiberacao().Equals(true))
                    {
                        string p = Session["IDPESSOA"].ToString().Trim();

                        bool liberacaoOficina = false;

                        int inatualizacaomonetariaacjud, incustasjudiciais, inhonorariocontratual, inhonorariosadvocaticios, inhonorariosucumbencia, injurosacjud, inmultaacjud, inreservadefesasegurado, invarcambialacjud;
                        decimal vlpagoatualizacaomonetariaacjud = 0, vlpagocustajudicial = 0, vlpagohonorariocontratual = 0, vlpagohonorariosadvocaticios = 0, vlpagosucumbencia = 0, vlpagojurosacjud = 0, vlpagomultaacjud = 0, vlpagoreservadefesasegurado = 0, vlpagovarcambialacjud = 0;
                        string strindacaojud = "";
                        short cddirec = 0;

                        if (!chkNaoIncluirAtualizacaoMonetaria.Checked && chkNaoIncluirAtualizacaoMonetaria.Enabled)
                            vlpagoatualizacaomonetariaacjud = Convert.ToDecimal(vlAtualizacaoMonetariaPago.Text.Trim());

                        if (!chkNaoIncluirCustasJudiciais.Checked && chkNaoIncluirCustasJudiciais.Enabled)
                            vlpagocustajudicial = Convert.ToDecimal(vlCustasJudiciaisPago.Text.Trim());

                        if (!chkNaoIncluirHonorarioContratual.Checked && chkNaoIncluirHonorarioContratual.Enabled)
                            vlpagohonorariocontratual = Convert.ToDecimal(vlHonorarioContratualPago.Text.Trim());

                        if (!chkNaoIncluirHonorariosAdvocaticios.Checked && chkNaoIncluirHonorariosAdvocaticios.Enabled)
                            vlpagohonorariosadvocaticios = Convert.ToDecimal(vlHonorariosAdvocaticiosPago.Text.Trim());

                        if (!chkNaoIncluirHonorarioSucumbencia.Checked && chkNaoIncluirHonorarioSucumbencia.Enabled)
                            vlpagosucumbencia = Convert.ToDecimal(vlHonorarioSucumbenciaPago.Text.Trim());

                        if (!chkNaoIncluirJurosDeMora.Checked && chkNaoIncluirJurosDeMora.Enabled)
                            vlpagojurosacjud = Convert.ToDecimal(vlJurosDeMoraPago.Text.Trim());

                        if (!chkNaoIncluirMulta.Checked && chkNaoIncluirMulta.Enabled)
                            vlpagomultaacjud = Convert.ToDecimal(vlMultaPago.Text.Trim());

                        if (!chkNaoIncluirReservaDefesaSegurado.Checked && chkNaoIncluirReservaDefesaSegurado.Enabled)
                            vlpagoreservadefesasegurado = Convert.ToDecimal(vlReservaDefesaSeguradoPago.Text.Trim());

                        //if (!chkNaoIncluirVariacaoCambial.Checked && chkNaoIncluirVariacaoCambial.Enabled)
                        //    vlpagovarcambialacjud = Convert.ToDecimal(vlVariacaoCambialPago.Text.Trim());

                        inatualizacaomonetariaacjud = chkNaoIncluirAtualizacaoMonetaria.Checked ? 1 : 0;
                        incustasjudiciais = chkNaoIncluirCustasJudiciais.Checked ? 1 : 0;
                        inhonorariocontratual = chkNaoIncluirHonorarioContratual.Checked ? 1 : 0;
                        inhonorariosadvocaticios = chkNaoIncluirHonorariosAdvocaticios.Checked ? 1 : 0;
                        inhonorariosucumbencia = chkNaoIncluirHonorarioSucumbencia.Checked ? 1 : 0;
                        injurosacjud = chkNaoIncluirJurosDeMora.Checked ? 1 : 0;
                        inmultaacjud = chkNaoIncluirMulta.Checked ? 1 : 0;
                        inreservadefesasegurado = chkNaoIncluirReservaDefesaSegurado.Checked ? 1 : 0;
                        invarcambialacjud = chkNaoIncluirVariacaoCambial.Checked ? 1 : 0;

                        decimal vlindenizacao = decimal.Parse(vltxtIndenizacao.Text.Trim());

                        DadosJudiciais oDJ = new DadosJudiciais();
                        oDJ.cod_aviso = int.Parse(txtProtocolo.Text.Trim());
                        oDJ.cod_direcionamento = short.Parse(txtSequencia.Text.Trim());
                        oDJ.cod_pester = string.IsNullOrEmpty(Request.QueryString["cdpester"]) ? -1 : int.Parse(Request.QueryString["cdpester"]);
                        oDJ.tipo_terceiro = string.IsNullOrEmpty(Request.QueryString["tpter"]) ? (short)-1 : short.Parse(Request.QueryString["tpter"]);

                        oDJ.recDadosJudiciaisTerceiro();

                        strindacaojud = oDJ.ind_defesa_segurado == 1 ? "N" : "S";
                        cddirec = oDJ.cod_direcionamento;

                        #region Valida Reativação

                        if (lblReabrirADM.Visible)
                        {
                            //Confirma Alçada
                            if (!Access.ValidateOneItem((DataSet)Session["ALLACCESS"], "ComunicacaoBase.pbreativar", Session["_ACT_MODULE"].ToString(), FunctionEnum.EFE))
                            {
                                MessageService.Alert("Usuário não Autorizado.", this);
                                return;
                            }

                            if (!Access.ValidateAccess((DataSet)Session["ALLACCESS"], "ComunicacaoReativacao.aspx"))
                            {
                                MessageService.Alert("Usuário não Autorizado.", this);
                                return;
                            }

                            AvisoSinistro oAS = new AvisoSinistro();
                            oAS.cod_aviso = oDJ.cod_aviso;
                            oAS.recAvisoSinistro();

                            Fs.Data.Sies.Emissao oEM = new Fs.Data.Sies.Emissao();
                            oEM.cod_contrato_seguro = oAS.cod_contrato_seg;
                            oEM.cod_emissao = oAS.cod_emissao;
                            oEM.recNumApolice();

                            string strRamo = oEM.cod_ramo_grupo.ToString("00") + oEM.cod_ramo_seguro.ToString();

                            //Verifica a possibilidade de Reativação
                            object[] obj = new object[9];
                            obj[0] = oEM.cod_orgao_produtor_sucursal.ToString();

                            if (strRamo.Length > 2)
                                obj[1] = strRamo.Substring(strRamo.Length - 2, 2);
                            else
                                obj[1] = strRamo;

                            obj[2] = oEM.num_apolice.ToString();
                            obj[3] = System.DBNull.Value;
                            obj[4] = System.DBNull.Value;
                            obj[5] = System.DBNull.Value;
                            obj[6] = System.DBNull.Value;
                            obj[7] = oAS.data_sinistro.ToShortDateString();
                            obj[8] = System.DBNull.Value;

                            oEM = new Fs.Business.Sies.Emissao();
                            oEM.ReferencePage = this;
                            DataSet ds = oEM.recEmissao123(obj);

                            if (ds.Tables[0].Rows.Count == 0)
                            {
                                MessageService.Alert("Emissão Não Encontrada para Reativação! Contate Sistemas!", this);
                                return;
                            }

                            if (ds.Tables[0].Rows[0]["nreds"].ToString().Trim() != oEM.num_endosso.ToString())
                            {
                                MessageService.Alert("Impossível realizar a Reativação: Existe Endosso com data retroativa a do Sinistro!", this);
                                return;
                            }

                            Fs.Business.Sinistro.CoberturaSinistro oCS = new Fs.Business.Sinistro.CoberturaSinistro();
                            oCS.cod_aviso = oAS.cod_aviso;
                            DataSet dsCS = oCS.recCoberturaSinistroAviso();

                            dsCS.Tables[0].Columns.Add("vltotindeniztxt", Type.GetType("System.String"));
                            dsCS.Tables[0].Columns.Add("vlpctfraobrtxt", Type.GetType("System.String"));

                            decimal decTotal = 0;
                            foreach (DataRow drCS in dsCS.Tables[0].Rows)
                            {
                                if (drCS["cdcobsin"].ToString() == ddlCobertura.SelectedValue)
                                {
                                    // ATENCAO - CUIDADO - O método já soma a Franquia ao vltotindeniz!!!
                                    // O valor apresentado na Grid representa o valor de indenização mais a franquia
                                    // O método já faz esta conta!!!
                                    drCS["vltotindeniztxt"] = Formatter.FormatCurrency(decimal.Parse(drCS["vltotindeniz"].ToString()));
                                    drCS["vlpctfraobrtxt"] = Formatter.FormatCurrency(decimal.Parse(drCS["vlpctfraobr"].ToString()));
                                    decTotal += (decimal.Parse(drCS["vltotindeniz"].ToString())
                                        - decimal.Parse(drCS["vlpctfraobr"].ToString())
                                        - decimal.Parse(drCS["vlpago"].ToString()))
                                        + (string.IsNullOrEmpty(vltxtIndenizacao.Text) ? 0 : decimal.Parse(vltxtIndenizacao.Text.Trim()));
                                }
                            }

                            decimal ValorTotalSinistro;
                            decimal ValorAjuste;

                            if (!Total(out ValorTotalSinistro, out ValorAjuste, dsCS.Tables[0].Rows))
                                return;

                            DataSet dsNew = new DataSet();
                            dsNew.Tables.Add("Coberturas");
                            dsNew.Tables[0].Columns.Add("cdcobsin", Type.GetType("System.Int16"));
                            dsNew.Tables[0].Columns.Add("vltotindeniz", Type.GetType("System.Decimal"));
                            dsNew.Tables[0].Columns.Add("vlpctfraobr", Type.GetType("System.Decimal"));

                            DataRow dr;
                            foreach (DataRow dgi in dsCS.Tables[0].Rows)
                            {
                                if (dgi["cdcobsin"].ToString() == ddlCobertura.SelectedValue)
                                {
                                    dr = dsNew.Tables[0].NewRow();
                                    dr["cdcobsin"] = dgi["cdcobsin"];

                                    dr["vltotindeniz"] = decimal.Parse(dgi["vltotindeniz"].ToString())
                                        - decimal.Parse(dgi["vlpctfraobr"].ToString())
                                        + (string.IsNullOrEmpty(vltxtIndenizacao.Text) ? 0 : decimal.Parse(vltxtIndenizacao.Text.Trim()));

                                    dr["vlpctfraobr"] = decimal.Parse(dgi["vlpctfraobr"].ToString());
                                    dsNew.Tables[0].Rows.Add(dr);
                                }
                            }

                            Fs.Business.Sinistro.ComunicacaoFactory oCFactory = new Fs.Business.Sinistro.ComunicacaoFactory();
                            string strErro;

                            oCFactory.Reativar(int.Parse(this.txtProtocolo.Text.Trim()),
                                ValorTotalSinistro, ValorAjuste, dsNew, false,
                                DateTime.Parse(Session["DATASISTEMA"].ToString()),
                                Session["USER"].ToString(), out strErro);

                            if (strErro.Trim() != "")
                            {
                                MessageService.Alert(strErro, this);
                                return;
                            }
                        }

                        #endregion

                        flag = oIS.ConsisteLiberaIndenizacao(int.Parse(txtProtocolo.Text.Trim()),
                               short.Parse(txtIndenizacao.Text.Trim()),
                               short.Parse(ddlCobertura.SelectedItem.Value),
                               int.Parse(Session["IDPESSOA"].ToString().Trim()),
                               rblLiquidacao.Items[Convert.ToInt32(LiquidacaoEnum.Parcial)].Selected,
                               rblLiquidacao.Items[Convert.ToInt32(LiquidacaoEnum.Total)].Selected,
                               Convert.ToDateTime(dttxtDataVencto.Text),
                               decimal.Parse(vltxtIndenizacao.Text.Trim()),
                               idget, answer, "", DateTime.Parse(Session["DATASISTEMA"].ToString()),
                               Session["USER"].ToString(), liberacaoOficina, 2,
                               0, 0, 0, 0,
                               0, 0, 0, 0,
                               inatualizacaomonetariaacjud, incustasjudiciais, inhonorariocontratual, inhonorariosadvocaticios,
                               inhonorariosucumbencia, injurosacjud, inmultaacjud, inreservadefesasegurado, invarcambialacjud,
                               vlpagoatualizacaomonetariaacjud, vlpagocustajudicial, vlpagohonorariocontratual, vlpagohonorariosadvocaticios,
                               vlpagosucumbencia, vlpagojurosacjud, vlpagomultaacjud, vlpagoreservadefesasegurado, vlpagovarcambialacjud,
                               true, strindacaojud, cddirec, oDJ.cod_pester, oDJ.tipo_terceiro, out warning);

                        if (Session["LIBPARCELAS"] != null)
                        {
                            Session.Remove("LIBPARCELAS");
                            dttxtDataVencto.Text = "";
                        }

                        if (flag)
                        {
                            this.Recuperar();
                            TabBase1.BotaoGravarEnabled = false;
                            TabBase1.BotaoExcluirEnabled = false;
                        }
                    }
                }
                else
                {
                    if (string.IsNullOrEmpty(warning).Equals(false))
                        MessageService.Alert(warning, this);
                    else
                    {
                        if (flagModal.Equals(false))
                        {
                            if (!flag)
                            {
                                MessageService.Alert("Cadastrar Nota Fiscal !", this);
                            }
                            else
                            {
                                if (flag)
                                {
                                    AlfaSegNET.Web.UI.WebControls.ToolBar.ToolBarItem itemTB =
                                        new AlfaSegNET.Web.UI.WebControls.ToolBar.ToolBarItem();
                                    itemTB.ItemTag = "Recuperar";
                                    TabBase1_ItemClick(itemTB);

                                    Session["NROINDENIZACAO"] = txtIndenizacao.Text.Trim();

                                    MessageService.Alert("Indenização Liberada !", this);
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception error)
            {
                MessageService.Alert("Operação não Efetuada ! Contate Sistemas.", this);
            }
        }

        private bool Total(out decimal vltotsinistro, out decimal decAjuste, DataRowCollection drCS)
        {
            vltotsinistro = 0;
            decAjuste = 0;
            try
            {
                bool bolAcada = Access.ValidateOneItem((DataSet)Session["ALLACCESS"],
                    "frmAvisoSinistro.IndSuperioIS", Session["_ACT_MODULE"].ToString(),
                    FunctionEnum.EFE);

                decimal decValorEstimativa = 0;
                decimal decValorSinistro = 0;
                decimal decValorIS = 0;
                decimal decValorFranquia = 0;
                decimal decValorFranquiaContratada = 0;

                foreach (DataRow dgi in drCS)
                {
                    if (dgi["cdcobsin"].ToString() == ddlCobertura.SelectedValue)
                    {
                        decValorEstimativa = (decimal.Parse(dgi["vltotindeniz"].ToString())
                            - decimal.Parse(dgi["vlpctfraobr"].ToString())
                            + decimal.Parse(vltxtIndenizacao.Text.Trim()));

                        if (decValorEstimativa < 0)
                        {
                            MessageService.Alert("Valor de Franquia Maior que Estimativa!", this);
                            return false;
                        }

                        if (!bolAcada)
                        {
                            decValorSinistro = decimal.Parse(dgi["vltotindeniz"].ToString());
                            decValorIS = decimal.Parse(dgi["vlsldis"].ToString());
                            decValorFranquia = decimal.Parse(dgi["vlpctfraobr"].ToString());
                            decValorFranquiaContratada = decimal.Parse(dgi["vlpctfrafcl"].ToString());

                            if (decValorSinistro > decValorIS)
                            {
                                MessageService.Alert("Valor de Indenização Maior que IS!", this);
                                return false;
                            }
                            if (decValorFranquiaContratada < decValorFranquia)
                            {
                                MessageService.Alert("Valor de Franquia Maior que a Contratada!", this);
                                return false;
                            }
                        }

                        vltotsinistro += decValorEstimativa;
                        decAjuste += (decValorEstimativa - decimal.Parse(dgi["vlpago"].ToString()));
                    }
                }

                if (decAjuste <= 0)
                {
                    MessageService.Alert("Reativar para um Valor Máximo de Indenização Maior que Zero!", this);
                    return false;
                }

                return true;
            }
            catch
            {
                MessageService.Alert("Operação não Efetuada. Contate Sistemas.", this);
                return false;
            }
        }

        /// <summary>
        /// Valida os campos para a Liberação 
        /// </summary>
        /// <returns></returns>
        private bool ValidarLiberacao()
        {
            bool validado = true;

            txtProtocolo.BackColor = Color.White;
            ddlCobertura.BackColor = Color.White;
            txtIndenizacao.BackColor = Color.White;
            txtProtocolo.BackColor = Color.White;
            vltxtIndenizacao.BackColor = Color.White;
            dttxtDataVencto.BackColor = Color.White;


            if (string.IsNullOrEmpty(txtProtocolo.Text.Trim()).Equals(true))
            {
                txtProtocolo.BackColor = Color.IndianRed;
                validado = false;
            }


            if (string.IsNullOrEmpty(ddlCobertura.Text.Trim()).Equals(true))
            {
                ddlCobertura.BackColor = Color.IndianRed;
                validado = false;
            }

            if (string.IsNullOrEmpty(txtIndenizacao.Text.Trim()).Equals(true))
            {
                txtIndenizacao.BackColor = Color.IndianRed;
                validado = false;
            }

            if (string.IsNullOrEmpty(txtProtocolo.Text.Trim()).Equals(true))
            {
                txtProtocolo.BackColor = Color.IndianRed;
                validado = false;
            }

            if (string.IsNullOrEmpty(vltxtIndenizacao.Text.Trim()).Equals(true))
            {
                vltxtIndenizacao.BackColor = Color.IndianRed;
                validado = false;
            }

            if (string.IsNullOrEmpty(dttxtDataVencto.Text.Trim()).Equals(true))
            {
                dttxtDataVencto.BackColor = Color.IndianRed;
                validado = false;
            }

            if (validado.Equals(false))
            {
                MessageService.Alert("Campos obrigatorios estão destacados em vermelho !", this);
            }
            else
            {
                DateTime data = new DateTime();

                if (DateTime.TryParse(dttxtDataVencto.Text.Trim(), out data).Equals(false))
                {
                    dttxtDataVencto.BackColor = Color.IndianRed;
                    dttxtDataVencto.Focus();
                    validado = false;
                    MessageService.Alert("Campo data de vencimento não é uma data valida !", this);
                }
                else
                {
                    decimal vl = 0;

                    if (decimal.TryParse(vltxtIndenizacao.Text.Trim(), out vl).Equals(false))
                    {
                        vltxtIndenizacao.BackColor = Color.IndianRed;
                        vltxtIndenizacao.Focus();
                        validado = false;
                        MessageService.Alert("Campo indenização  com valor númerico incompativel !", this);
                    }
                }

            }

            return validado;

        }

        private void MenuInferior(bool devolucao)
        {

            MenuItem item = new MenuItem();
            item.Text = "";
            item.Value = "0";
            TabFooter1.Items.Add(item);

            item = new MenuItem();
            item.Text = "Liberar";
            item.Value = "1";
            item.Enabled = true;
            item.ImageUrl = "IMG/setb.gif";
            item.ToolTip = "Clique para liberar";
            TabFooter1.Items.Add(item);

            if (devolucao == false)
            {
                item = new MenuItem();
                item.Text = "";
                item.Value = "2";
                item.Enabled = true;
                item.ToolTip = "";
                item.ImageUrl = "";
                TabFooter1.Items.Add(item);
            }
            else
            {
                item = new MenuItem();
                item.Text = "Devolução";
                item.Value = "2";
                item.Enabled = true;
                item.ToolTip = "Clique para realizar a Devolução dos arquivos em anexo";
                item.ImageUrl = "IMG/setb.gif";
                TabFooter1.Items.Add(item);
            }

            item = new MenuItem();
            item.Text = "Cancelar";
            item.Value = "3";
            item.Enabled = true;
            item.ToolTip = "Clique para cancelar";
            item.ImageUrl = "IMG/setb.gif";
            TabFooter1.Items.Add(item);


            //  ddlAnexos.Enabled = false;

        }
        private void LimparMenuInferior()
        {

            for (int i = TabFooter1.Items.Count; i > 0; i--)
            {
                TabFooter1.Items.Remove(TabFooter1.Items[0]);
            }

        }
    }
}
