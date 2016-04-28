describe('home page', () => {

	it('should have a title', () => {
		browser.get('http://localhost:9001/home');
		const h1 = element(by.css('h1'));
		expect(h1.getText()).toEqual('Hello');
	});

});