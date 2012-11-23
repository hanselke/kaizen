x=require('./app/js/suppliers.js')
fs=require('fs')
s={}
x.suppliers.forEach(function(i){
	s[i.ID]={
		PartyIDs: {ID: [i.ID]},
		Name: i.Name,
		Location:{Address:{
			AddressLine: [i.Line1],
			CityName: "Singapore",
			CountryCode: "SG",
			PostalCode: i.PostalCode
		}},
		Contact: {
		  Name: null,
		  Communication: {
			  UserArea: {
				Phone: "",
				Fax: "",
				Email: ""
			  }
		  }
		}
	}
})                                                              
fs.writeFileSync('./suppliers.js', 'exports.list = ' + JSON.stringify(s,null,'\t'))
