import requests

url = "https://citibikenyc.com/bikesharefe-gql"
headers = {
    "Host": "citibikenyc.com",
    "Accept": "*/*",
    "Sec-Fetch-Site": "same-origin",
    "Accept-Language": "en-US,en;q=0.9",
    "Sec-Fetch-Mode": "cors",
    "Origin": "https://citibikenyc.com",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5.2 Safari/605.1.15",
    "Referer": "https://citibikenyc.com/explore",
    "Connection": "keep-alive",
    "Sec-Fetch-Dest": "empty",
    "Content-Type": "application/json"
}
data = {
    "operationName": "GetSupply",
    "variables": {
        "input": {
            "regionCode": "BKN",
            "rideablePageLimit": 1000
        }
    },
    "query": """fragment NoticeFields on Notice {
  localizedTitle
  localizedDescription
  url
  __typename
}

query GetSupply($input: SupplyInput) {
  supply(input: $input) {
    stations {
      stationId
      stationName
      location {
        lat
        lng
        __typename
      }
      bikesAvailable
      bikeDocksAvailable
      ebikesAvailable
      scootersAvailable
      totalBikesAvailable
      totalRideablesAvailable
      isValet
      isOffline
      isLightweight
      notices {
        ...NoticeFields
        __typename
      }
      siteId
      ebikes {
        rideableName
        batteryStatus {
          distanceRemaining {
            value
            unit
            __typename
          }
          percent
          __typename
        }
        __typename
      }
      scooters {
        rideableName
        batteryStatus {
          distanceRemaining {
            value
            unit
            __typename
          }
          percent
          __typename
        }
        __typename
      }
      lastUpdatedMs
      __typename
    }
    rideables {
      rideableId
      location {
        lat
        lng
        __typename
      }
      rideableType
      photoUrl
      batteryStatus {
        distanceRemaining {
          value
          unit
          __typename
        }
        percent
        __typename
      }
      __typename
    }
    notices {
      ...NoticeFields
      __typename
    }
    requestErrors {
      ...NoticeFields
      __typename
    }
    __typename
  }
}
"""
}

response = requests.post(url, headers=headers, json=data)
response_json = response.json()

print(response_json)
