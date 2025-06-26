
# Interface encoding TBC
$client_id = "your-client-id"
$client_secret = "your-client-secret"
$redirect_Uri = "https://your-redirect-uri"


# End Points for URL Authentication
$auth_url = "https://login.eveonline.com/v2/oauth/authorize"
$token_url = "https://login.eveonline.com/v2/oauth/token"


# Step 1: Get authorization code
$scopes = "esi-location.read_location.v1 esi-location.read_ship_type.v1 esi-characters.read_contacts.v1 esi-characters.read_loyalty.v1 esi-characters.read_opportunities.v1 esi-characters.read_standings.v1 esi-characters.read_titles.v1 esi-characters.write_contacts.v1 esi-characters.write_opportunities.v1 esi-characters.write_standings.v1 esi-characters.write_titles.v1"
$auth_url = ""
