# requires pyjwt (https://pyjwt.readthedocs.io/en/latest/)
# pip install pyjwt


import datetime
import jwt


secret = """-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgV7pzYPnw0GF6jjDi
SoJDkGi5At2mWk/9dL2YzgHU9eCgCgYIKoZIzj0DAQehRANCAARCMogmgEKRji1z
htfGxF5y4wpMQtkSTIGEs3alOAfFFlU+9TMoEU/is/jBmt5M/Guu9GVvU+YDZqOI
sofzjwzc
-----END PRIVATE KEY-----"""
keyId = "CHBHQCZX3J"
teamId = "JAL7GH5GRG"
alg = 'ES256'

time_now = datetime.datetime.now()
time_expired = datetime.datetime.now() + datetime.timedelta(hours=12)

headers = {
	"alg": alg,
	"kid": keyId
}

payload = {
	"iss": teamId,
	"exp": int(time_expired.strftime("%s")),
	"iat": int(time_now.strftime("%s"))
}


if __name__ == "__main__":
	"""Create an auth token"""
	token = jwt.encode(payload, secret, algorithm=alg, headers=headers)

	print "----TOKEN----"
	print token

	print "----CURL----"
	print "curl -v -H 'Authorization: Bearer %s' \"https://api.music.apple.com/v1/catalog/us/artists/36954\" " % (token)

