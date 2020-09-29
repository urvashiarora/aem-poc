'use strict';

describe('Protractor Demo Page', () => {
	it('should have a title', () => {
		browser.get('http://juliemr.github.io/protractor-demo');
		expect(browser.getTitle()).toEqual('Super Calculator');
	});
});

