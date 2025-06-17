import diskcache
from dash import Dash
from dash.long_callback import DiskcacheLongCallbackManager
import dash_bootstrap_components as dbc

cache = diskcache.Cache("./cache")
background_callback_manager = DiskcacheLongCallbackManager(cache)

app4 = Dash(__name__,
            external_stylesheets=[dbc.themes.COSMO],
            assets_folder="assets",
            long_callback_manager=background_callback_manager
            )
application = app4.server
