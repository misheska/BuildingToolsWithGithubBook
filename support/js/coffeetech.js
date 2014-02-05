// BEGIN MODULE_DEFINITION
var mod = angular.module( 'coffeetech', [] );

mod.factory( 'Github', function() {
    return new Github({});
});
// END MODULE_DEFINITION

mod.factory( 'Geo', [ '$window', function( $window ) {
    return $window.navigator.geolocation;
} ] );

mod.controller( 'GithubCtrl', [ '$scope', 'Github', 'Geo', function( $scope, ghs, Geo ) {
    $scope.messages = []

    $scope.init = function() {
        $scope.getCurrentLocation( function( position ) {
            $scope.latitude = position.coords.latitude;
            $scope.longitude = position.coords.longitude;
            $scope.repo = ghs.getRepo( "xrd", "spa.coffeete.ch" ); // # <1>
            $scope.repo.read( "gh-pages", "cities.json", function(err, data) { // # <2>
                $scope.cities = JSON.parse( data ); // # <3>
                // Determine our current city
                $scope.detectCurrentCity();

                // If we have a city, get it
                if( $scope.city ) {
                    $scope.retrieveCity();
                }

                $scope.$apply();
            });
        });
    };

    $scope.retrieveCity = function() {
        $scope.repo.read( "gh-pages", $scope.city.name + ".json", function(err, data) { 
            $scope.shops = JSON.parse( data );
            $scope.$apply();
        });
    }

    $scope.getCurrentLocation = function( cb ) {
        if( undefined != Geo ) {
            Geo.getCurrentPosition( cb, $scope.geolocationError );
        } else {
            console.error('not supported');
        }
        
    };

    $scope.detectCurrentCity = function() {
        // Calculate the distance from our current position and use
        // this to determine which city we are closest to and within
        // 25 miles
        for( var i = 0; i < $scope.cities.length; i++ ) {
            var dist = $scope.calculateDistance( $scope.latitude, $scope.longitude, $scope.cities[i].latitude, $scope.cities[i].longitude );
            if( dist < 25 ) {
                $scope.city = $scope.cities[i];
                break;
            }
        }
    }

    toRad = function(Value) {
        return Value * Math.PI / 180;
    };
    
    $scope.calculateDistance = function( latitude1, longitude1, latitude2, longitude2 ) {
        R = 6371;
        dLatitude = toRad(latitude2 - latitude1);
        dLongitude = toRad(longitude2 - longitude1);
        latitude1 = toRad(latitude1);
        latitude2 = toRad(latitude2);
        a = Math.sin(dLatitude / 2) * Math.sin(dLatitude / 2) + Math.sin(dLongitude / 2) * Math.sin(dLongitude / 2) * Math.cos(latitude1) * Math.cos(latitude2);
        c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        d = R * c;
        return d;
    }

    $scope.loadCity = function( city ) {
        $scope.repo.read( "gh-pages", city + ".json", function(err, data) { // # <2>
            $scope.shops = JSON.parse( data ); // # <3>
            $scope.$apply();
        });
    }
    
    $scope.geolocationError = function( error ) {
        console.log( "Inside failure" );
    };
    

} ] );

