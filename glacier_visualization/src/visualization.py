from dash import html, dcc
from dash.dependencies import Input, Output
import plotly.graph_objects as go
import plotly.subplots as ps
from data_collector import DataCollector
from dash import Dash, ctx
from app import app4 as app

collector = DataCollector()

body = html.Div(
    [
        html.H1(
            children="Glacier Time Series Visualization",
            style={"text-align": "center"}),
        html.Div(
            className='dropdown-container',
            children=[
                html.Div(
                    className='dropdown',
                    children=[
                        html.Div(
                            'Gate Number:'
                        ),
                        html.Div(
                            className='dropdown-inner',
                            children=
                            dcc.Dropdown(
                                options=collector.get_available_gate_numbers(),
                                id="gate-number-dropdown",
                                placeholder='Select Gate Number',
                                value=1,
                            )
                        )

                    ]
                ),
                html.Div(
                    className='dropdown',
                    children=[
                        html.Div(
                            'Year:'
                        ),
                        html.Div(
                            className='dropdown-inner',
                            children=dcc.Dropdown(
                                options=['2015', '2016', '2017', '2018', '2019', '2020'],
                                id="year-dropdown",
                                placeholder='Select Year',
                                value='2015',
                            ),
                        )

                    ]
                )

            ]
        ),

        html.Div(
            children=[
                html.Button(
                    id='back-button',
                    className='button',
                    children='← Back'
                ),
                html.Div(
                    className='glacier-metadata-box',
                    children=[
                        html.H2(id='glacier-metadata-name', className='glacier-metadata'),
                        html.H4(
                            [
                                html.B("Gate "),
                                html.Div(id='glacier-metadata-gate-number'),
                            ],
                            className='glacier-metadata'
                        ),
                        html.Hr(style={'border-top': '3px solid black'}),
                        html.Div(
                            [
                                html.B('Coordinate:'),
                                html.Div(id='glacier-metadata-coordinate')
                            ],
                            className='glacier-metadata'
                        ),
                        html.Div(
                            [
                                html.B('Total Iceberg Count:'),
                                html.Div(id='glacier-metadata-average-ice-count')
                            ],
                            className='glacier-metadata'
                        ),
                        html.Hr(style={'border-top': '3px solid black'}),
                    ]
                ),
                html.Button(
                    'Next →',
                    id='next-button',
                    className='button'

                )
            ],
            style={
                'display': 'flex',
                'justify-content': 'space-between',
                'align-items': 'center',
                'padding-top': '5%'
            }
        ),
        html.Div(
            children=[
                html.Div(id="gate-number-tester"),
            ],
            id="glacier-info"
        ),
        html.Div(
            className="top-block",
            children=[
                html.Div(
                    dcc.Graph(
                        id="geo-location",
                        style={
                            'width': '100%',
                            'height': '100%',
                        },
                        config={'responsive': True},
                    ),
                    className="location-plot",
                ),
                html.Div(
                    dcc.Tabs(
                        className='tab-container',
                        # style={
                        #     'height': '50px'
                        # },
                        children=[
                            dcc.Tab(
                                label='Mapped Location On Geo Map',
                                children=
                                dcc.Graph(
                                    id="mapped-point",
                                    config={'responsive': True},
                                    style={
                                        'height': '650px'
                                    }
                                ),

                            ),
                            dcc.Tab(
                                label='Mapped Location On Bathymetry Map',
                                children=
                                dcc.Graph(
                                    id='location-masked-plot',
                                    style={
                                        'height': '650px'
                                    },
                                    config={'responsive': True},
                                ),
                                style={
                                    # 'height': '800px'
                                }
                            )
                        ],

                    ),

                    className="location-plot",

                )
            ],
            style={
                'display': 'flex',
                'flex-direction': 'row',
                'justify-content': 'space-between',
            }
        ),
        html.Div(
            className='mid-block',
            children=[
                dcc.Graph(
                    id='iceberg-count-plot',
                    style={
                        # 'position': 'relative',
                        # 'overflow': 'hidden',
                    }
                ),
                dcc.Graph(
                    id='iceberg-count-logged-plot',
                    style={
                        # 'position': 'relative',
                        # 'overflow': 'hidden'
                    }
                )
            ],
            style={
                'display': 'flex',
                'flex-direction': 'row',
                'justify-content': 'space-between',
                # 'gap': '5%',
                # 'align-items': 'center',
            }
        ),
        html.Div(
            className='bottom-block',
            children=[
                dcc.Graph(
                    id='glacier-dimensions',
                    style={
                        # 'position': 'absolute',

                        'width': '100%',
                        'height': '100%',
                    },
                    config={'responsive': True},
                )
            ],

        )
    ],
    style={
        "margin-left": "5%",
        "margin-right": "5%"
    }
)


def create_visualization_page():
    layout = html.Div(
        [
            body
        ]
    )
    return layout


@app.callback(
    Output('gate-number-dropdown', 'value'),
    Input('gate-number-dropdown', 'value'),
    Input('next-button', 'n_clicks'),
    Input('back-button', 'n_clicks'),
    prevent_initial_call=True
)
def update_gate(dropdown_val, next_button, back_button):
    index = dropdown_val

    trigger = ctx.triggered_id

    if trigger == 'next-button':
        index = collector.get_next_available_gate_number()

    elif trigger == 'back-button':
        index = collector.get_previous_available_gate_number()

    else:
        collector.set_current_gate_number(index)

    return index


@app.callback(
    Output("glacier-metadata-name", "children"),
    Input("gate-number-dropdown", "value")
)
def update_gate_name(value):
    return collector.get_glacier_name(gate_number=value)


@app.callback(
    Output("glacier-metadata-gate-number", "children"),
    Input("gate-number-dropdown", "value")
)
def update_gate_number(value):
    return f' #{value}'


@app.callback(
    Output("glacier-metadata-coordinate", "children"),
    Input("gate-number-dropdown", "value")
)
def update_gate_coordinate(value):
    x, y = collector.get_glacier_original_coordinates(gate_number=value)
    u = 'E' if x >= 0 else 'W'
    v = 'N' if y >= 0 else 'S'
    return f' {abs(x):.4f} {u}, {y:.4f} {v}'


@app.callback(
    Output("glacier-metadata-average-ice-count", "children"),
    Input("gate-number-dropdown", "value")
)
def update_gate_avg_ice_count(value):
    avg_ice_count = collector.get_flux_data_by_year(value, 1992).mean()
    return f' {avg_ice_count:.4f}'


@app.callback(
    Output("geo-location", "figure"),
    Input("gate-number-dropdown", "value")
)
def geo_location_plot(value):
    x, y = collector.get_glacier_original_coordinates(gate_number=value)
    row, col = collector.get_glacier_original_row_col(gate_number=value)
    name = collector.get_glacier_name(gate_number=value),
    fig = go.Figure(
        go.Scattermap(
            lon=[x],
            lat=[y],
            mode="markers",
            marker=go.scattermap.Marker(
                size=10
            ),
            customdata=[[name, int(row), int(col)]],
            hovertemplate="<br>".join([
                "%{customdata[0]}",
                "Coordinate: %{lon}, %{lat}",
                "Row: %{customdata[1]}",
                "Col: %{customdata[2]}"
            ])
        ),
    )
    fig.update_layout(
        hovermode='closest',
        map=dict(
            bearing=0,
            center=go.layout.map.Center(
                lat=74.0,
                lon=-42.6043
            ),
            pitch=0,
            zoom=2
        ),
        title="Geographic Location",
        map_style="satellite"
    )
    fig = change_fig_background_color(fig)
    return fig


@app.callback(
    Output("mapped-point", "figure"),
    Input("gate-number-dropdown", "value")
)
def mapped_location_plot(value):
    x, y = collector.get_glacier_original_coordinates(gate_number=value)
    mapped_x, mapped_y = collector.get_glacier_mapped_coordinate(gate_number=value)
    row, col = collector.get_glacier_original_row_col(gate_number=value)
    mapped_row, mapped_col = collector.get_glacier_mapped_row_col(gate_number=value)
    fig = go.Figure(
        go.Scattermap(
            lat=[y, mapped_y],
            lon=[x, mapped_x],
            mode="markers+lines",
            marker=go.scattermap.Marker(
                size=14,
                color=['blue', 'red'],
            ),
            customdata=[[row, col], [mapped_row, mapped_col]],
            hovertemplate='<br>'.join([
                'Coordinate: %{lon}, %{lat}',
                'Row: %{customdata[0]}',
                'Col: %{customdata[1]}'
            ])
        ),
    )

    fig.update_layout(
        hovermode='closest',
        map=dict(
            bearing=0,
            center=go.layout.map.Center(
                lat=y,
                lon=x
            ),
            pitch=0,
            zoom=3.5,

        ),
        map_style="satellite"
    )

    fig = change_fig_background_color(fig)
    return fig


@app.callback(
    Output('iceberg-count-plot', 'figure'),
    Input("gate-number-dropdown", "value")
)
def iceberg_count_plot(value):
    timeseries_data = collector.get_flux_data_by_year(value, 1992)
    fig = go.Figure(
        go.Scatter(
            x=timeseries_data.index,
            y=timeseries_data
        )
    )

    fig.update_layout(
        title='Iceberg Count',
        xaxis_title='Year',
        yaxis_title='Count',
        xaxis=dict(showgrid=False, gridcolor='black', zeroline=True, zerolinecolor='red'),  # Change gridline color
        yaxis=dict(showgrid=True, gridcolor='black', zeroline=True, zerolinecolor='red'),
    )
    fig = change_fig_background_color(fig)
    return fig


@app.callback(
    Output('iceberg-count-logged-plot', 'figure'),
    Input('gate-number-dropdown', 'value')
)
def iceberg_count_logged_plot(value):
    data = collector.get_log_count_by_year(value)
    fig = go.Figure(
        go.Bar(
            x=data[:, 0],
            y=data[:, 1]
        )
    )

    fig.update_layout(
        title='Iceberg Log Count',
        xaxis_title='Glacier Volume',
        yaxis_title='Iceberg Count',
        xaxis=dict(showgrid=False, gridcolor='black', zeroline=True, zerolinecolor='red'),  # Change gridline color
        yaxis=dict(showgrid=True, gridcolor='black', zeroline=True, zerolinecolor='red'),
    )
    fig = change_fig_background_color(fig)
    return fig


@app.callback(
    Output('glacier-dimensions', 'figure'),
    Input('gate-number-dropdown', 'value')
)
def glacier_dimensions_plot(value):
    name, time, df = collector.get_glacier_dimension(value)
    fig = ps.make_subplots(rows=3, cols=1, shared_xaxes=True, vertical_spacing=0.1,
                           subplot_titles=['Widths', 'Thickness', 'Volumes'], x_title='Time')

    fig.add_trace(
        go.Scatter(
            x=time,
            y=df[:, 1], mode='markers',
        ), row=1, col=1,
    )

    fig.add_trace(
        go.Scatter(
            x=time,
            y=df[:, 2], mode='markers',
        ), row=2, col=1,
    )

    fig.add_trace(
        go.Scatter(
            x=time,
            y=df[:, 3], mode='markers',
        ), row=3, col=1,
    )

    fig.update_layout(
        title=f'Dimensions timeseries of {name}',
        showlegend=False,
    )

    fig.update_yaxes(
        dict(showgrid=True, gridcolor='black', zeroline=True, zerolinecolor='red', title='(m)'),
        # Change gridline color
        row=1, col=1
    )

    fig.update_yaxes(
        dict(showgrid=True, gridcolor='black', zeroline=True, zerolinecolor='red', title='(m)'),
        # Change gridline color
        row=2, col=1
    )

    fig.update_yaxes(
        dict(showgrid=True, gridcolor='black', zeroline=True, zerolinecolor='red', title='(m^3)'),
        # Change gridline color
        row=3, col=1
    )

    fig = change_fig_background_color(fig)
    return fig


@app.callback(
    Output('location-masked-plot', 'figure'),
    Input('gate-number-dropdown', 'value')
)
def location_masked_plot(value):
    data = collector.get_mask_map_with_points(value)
    fig = go.Figure(
        data=go.Heatmap(
            z=data,
            colorscale=[
                [0, 'white'],
                [0.33, 'gray'],
                [0.66, 'blue'],
                [1, 'red']
            ],
            hoverongaps=False,
            showscale=True,
            colorbar=dict(
                title='Type',
                tickvals=[0, 1, 2, 3],  # Location of ticks
                ticktext=['Land', 'Water', 'Original', 'Mapped'],  # Labels for each tick
            )
        )
    )
    fig.update_layout(
        autosize=True,
        margin=dict(l=0, r=0, t=20, b=0),  # minimize margins
        xaxis=dict(
            constrain='domain',
            range=[45, 180]
        ),
        yaxis=dict(
            scaleanchor='x',  # fix aspect ratio
            scaleratio=0.6,
            range=[170, 350]
        ),
    )
    fig = change_fig_background_color(fig)
    return fig


def change_fig_background_color(fig):
    fig.update_layout(
        paper_bgcolor='#f0f8ff',
        plot_bgcolor='#f0f8ff',
    )
    return fig
if __name__ == "__main__":
    app.run(debug=False)
