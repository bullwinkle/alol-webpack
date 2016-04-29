@Iconto.module 'office', (Office) ->

	Office.companyController = new Office.CompanyController()
	Office.controller = new Office.Controller()


	Office.helperRouter = new Office.HelperRouter controller: Office.controller

	Office.companyHelperRouter = new Office.CompanyHelperRouter controller: Office.companyController

	Office.router = new Office.Router controller: Office.controller

	Office.companyRouter = new Office.CompanyRouter controller: Office.companyController