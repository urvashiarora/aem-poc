'use strict';

require('babel-core/register');
const CommonConfig = require('./reportersConfig.js');

exports.config = {
	directConnect: true,
	framework: 'jasmine2',
	specs: ['../tests/test.js'],

	capabilities: {
		browserName: 'chrome',
		chromeOptions: {
			args: ['--disable-gpu', '--window-size=1366x768']
		}
	},

	jasmineNodeOpts: {
		showColors: true,
		isVerbose: true
	},

	params: {
		timeout: 5000
	},

	onPrepare: function () {
		browser.baseUrl = 'http://localhost:4502';
		CommonConfig.setupJasmine();
	}
};
