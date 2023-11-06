  var placeSearch, autocomplete, id_, selected, old_value;
  var componentForm = {
  street_number: 'short_name',
  route: 'short_name',
  locality: 'long_name',
  administrative_area_level_1: 'short_name',
  postal_code: 'short_name'
  };

  function initAutocomplete() {
    selected = false;
    autocomplete = new google.maps.places.Autocomplete(
        (document.getElementById('autocomplete')),
        {types: ['geocode']});

    autocomplete.addListener('place_changed', fillInAddress);
  }

  function initAutocomplete_( v ) {
    selected = false;
    autocomplete = new google.maps.places.Autocomplete(
        (document.getElementById( v )),
        {types: ['geocode']});
    autocomplete.addListener('place_changed', fillInAddress);
    if (!selected){
      var x = document.getElementById(v);
      x.addEventListener("blur", myBlurFunction, true);
    }
  }

  function myBlurFunction() {
    if (old_value != document.getElementById(id_).value){
      document.getElementById(id_).value = "";
    }
  }


  function fillInAddress() {
    selected = true
    var place = autocomplete.getPlace();
    var NewVar = id_.replace("autocomplete_", "");
    for (var component in componentForm) {
      document.getElementById(component + '_' + NewVar).value = '';
      document.getElementById(component + '_' + NewVar).disabled = false;
    }

    for (var i = 0; i < place.address_components.length; i++) {
      var addressType = place.address_components[i].types[0];
      if (componentForm[addressType]) {
        var val = place.address_components[i][componentForm[addressType]];
        document.getElementById(addressType + '_' + NewVar).value = val;
      }
    }
    document.getElementById('longitude_' + NewVar).value = place.geometry.location.lng();
    document.getElementById('latitude_' + NewVar).value = place.geometry.location.lat();
    if ($('#restaurants_map').length) {
      markers.push([place.address_components[0].long_name+" :"+place.formatted_address, place.geometry.location.lat(), place.geometry.location.lng(), 'http://maps.google.com/mapfiles/kml/paddle/blu-circle.png', '']);
      infoWindowContent.push([place.address_components[0].long_name+" :"+place.formatted_address]);
      extendWithMarkers(markers, (markers.length)-1);
      map.setZoom(15);
      map.setCenter(gmarkers[(markers.length)-1].getPosition());
    }
  }

  function geolocate( v ) {
    id_ = v.id
    old_value = document.getElementById(id_).value
    initAutocomplete_( v.id );
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(function(position) {
      var geolocation = {
        lat: position.coords.latitude,
        lng: position.coords.longitude
      };
      var circle = new google.maps.Circle({
        center: geolocation,
        radius: position.coords.accuracy
      });
      autocomplete.setBounds(circle.getBounds());
    });
  }
  }