describe('calc page', () => {

	browser.get('/calc');

	it('should have a title',  () => {
		const h1 = element(by.css('h1'));
		expect(h1.getText()).toEqual('Hello world!');
	});

});