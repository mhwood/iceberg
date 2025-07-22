from dash import html, dcc
from dash.dependencies import Input, Output
from app import app4
import os
from home import create_home_layout
from visualization import create_visualization_page

application = app4.server
app4.config.suppress_callback_exceptions = True

app4.layout = html.Div([
    dcc.Location(id='url', refresh=True),
    html.Div(id='page-content'),
    dcc.Store(id='process-output-store'),
    # dcc.Store(id='original-data', data=original_data.to_dict('records')),
    # dcc.Store(id='ml-prediction', data=ml_prediction.to_dict('records'))
])

@app4.callback(Output('page-content', 'children'),
              [Input('url', 'pathname')])
def display_page(pathname):
    if pathname == '/visualization' and os.path.exists(os.path.join('data', 'glacier_data.csv')):
        return create_visualization_page()
    # Only show homepage if path is empty or root
    if pathname in [None, '/', '']:
        return create_home_layout()
    # Optionally show a 404-style message for unrecognized paths
    return html.Div("404: Page not found")


if __name__ == '__main__':
    app4.run_server(debug=True)
