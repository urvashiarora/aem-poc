const jasmine2HtmlReporter = require('protractor-jasmine2-html-reporter');
const SpecReporter = require('jasmine-spec-reporter').SpecReporter;

class CommonConfig {

	static setupJasmine() {
		const env = jasmine.getEnv();

		const htmlReporter = new jasmine2HtmlReporter({
			savePath: 'build/protractor/html',
			screenshotsFolder: 'images'
		});

		const specReporter = new SpecReporter({
			spec: {
				displayStacktrace: 'pretty'
			}
		});

		env.addReporter(htmlReporter);
		env.addReporter(specReporter);
	}
}

export default CommonConfig
