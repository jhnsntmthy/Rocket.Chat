Package.describe({
	name: 'rocketchat:pubnub',
	version: '0.0.1',
	summary: 'RocketChat Connector for Pubnub Channel Groups',
	git: ''
});

Npm.depends({
	'coffee-script': '1.9.3',
	'lru-cache': '2.6.5',
	'pubnub': '3.14.1'
});

Package.onUse(function(api) {
	api.versionsFrom('1.0');

	api.use([
		'coffeescript',
		'underscore',
		'rocketchat:lib',
	]);

	api.addFiles('pubnub.connect.coffee', 'server');
	api.export(['Pubnub'], ['server']);
});

Package.onTest(function(api) {});
