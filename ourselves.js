var utils = require('utils'); utils.init(Object)
var oagis = require('./oagis')

exports.party = oagis.SupplierPartyType.extend({
	PartyIDs: {ID: [0]},   // what this should be?
	AccountID: 0,   // not sure what is this...
	Name: 'Guan Huat Hardware Pte. Ltd.',
	Location: {
		ID: null,
		Address: {
			ID: [],
			AttentionOfName: 'Derrick',
			AddressLine: ['3 Irving Road, Irving Industrial Building #06-08'],
			CityName: 'Singapore',
			CountryCode: 'SG',
			PostalCode: '369522'
		}
	},
	Contact: {
		Name: 'Derrick',
		Communication: {
			UserArea: {
				Phone: "+65 9631-6409",
				Fax: "+65 6288-5135",
				Email: "sales@guanhuathardware.com"
			}
		}
	},
})
