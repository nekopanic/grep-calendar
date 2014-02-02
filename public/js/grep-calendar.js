/**
 * Services
 */
var grepCalendarServices = angular.module('grepCalendarServices', ['ngResource']);

grepCalendarServices.factory('Calendar', ['$resource',
    function($resource) {
        return $resource('calendar.json?', {}, { get: {method:'GET', params:{url:'url'}}});
        return $resource('calendar.json?', {}, { grep: {method:'GET', params:{url:'url', query: 'query'}}});
    }
  ]
);

/**
 * Application and Controllers
 */
var grepCalendarApp = angular.module('grepCalendarApp', ['ngRoute','grepCalendarServices']);

grepCalendarApp.controller('GrepCalendarCtrl', ['$scope', '$location', 'Calendar', function ($scope, $location, Calendar) {

    $scope.calendar = {};

    $scope.getCalendar = function(calendar) {
        $scope.calendar = { url: calendar.url }; // This is to totally reset the calendar object
        $scope.calendar.urlLoading = true;
        Calendar.get({url: calendar.url}, getCalendarSuccess, getCalendarError);
    }

    var getCalendarSuccess = function(c, headers) {
        $scope.calendar.urlLoading = false;
        $scope.calendar.content = c.calendars;
    };

    var getCalendarError = function(e, headers) {
        $scope.calendar.urlLoading = false;
        $scope.calendar.getError = e.data;
    };

    $scope.grepCalendar = function(calendar) {
        calendar.grepped = null;
        calendar.grepError = null;
        calendar.grepLoading = true;
        Calendar.get({url: calendar.url, query: calendar.query}, grepCalendarSuccess, grepCalendarError);
    };

    var grepCalendarSuccess = function(c, headers) {
        $scope.calendar.grepLoading = false;
        $scope.calendar.grepped = c.calendars;
        $scope.calendar.grepUrl = c.url;
    };

    var grepCalendarError = function(e, headers) {
        $scope.calendar.grepLoading = false;
        $scope.calendar.grepError = e.data;
    };
}]);

