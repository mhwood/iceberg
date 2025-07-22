import dash
from dash import html, dcc, ctx, clientside_callback
from dash.dependencies import Input, Output, State
from dash.exceptions import PreventUpdate
from app import app4 as app
import io
import sys
import subprocess
import sys
import time
from functools import lru_cache


@lru_cache(maxsize=1)
def create_home_layout():
    layout = html.Div(
        children=[
            html.H1("Glacier Calving Schedule App", style={"text-align": "center"}),
            html.H2("Welcome to Glacier Calving Schedule App", style={"text-align": "center"}),
            html.Div(
                children=[
                    html.Div(
                        className='year-form-container',
                        children=[
                            html.Div(
                                'Enter year(s):'
                            ),
                            html.Div(
                                dcc.Input(
                                    id='year-input',
                                    style={
                                        'width': '100%'
                                    }
                                ),
                                style={'width': '80%'}
                            )

                        ]
                    ),
                    html.Div(
                        className='length-form-container',
                        children=[
                            html.Div(
                                'Enter calving schedule length:'
                            ),
                            html.Div(
                                dcc.Input(
                                    id='length-input',
                                    style={
                                        'width': '100%'
                                    }
                                ),
                                style={'width': '80%'}
                            )

                        ]
                    ),
                ]
            ),
            html.Div(
                html.Button(
                    'Test Terminal',
                    id='show-output-button',
                    className='button',
                ),
                style={
                    'display': 'flex',
                    'justify-content': 'flex-end'
                }
            ),
            html.Div(
                [
                    html.Pre(
                        id='output-text',
                        children=[],
                        style={
                            'overflow-y': 'scroll'
                        }
                    ),
                    html.Div(id='scroll-trigger', style={'display': 'none'}),
                    dcc.Interval(
                        id='interval-component',
                        interval=100,  # Update every 200 milliseconds (adjust as needed)
                        n_intervals=0,
                        disabled=True  # Start disabled, enable when process starts
                    ),
                ]
            ),
            html.Button(
                id='moving-to-viz',
                children='Move to visualization',
                className='button',
                disabled=True,
                n_clicks=0
            ),
            html.Div(id='scroll-dummy', style={'display': 'none'}, children="")

        ],
        style={
            'padding-left': '5%',
            'padding-right': '5%',
            'padding-top': '5%',
            'padding-bottom': '5%',
        }
    )
    return layout


def get_terminal_output(mitgrid_input, gate_input):
    old_stdout = sys.stdout
    new_stdout = io.StringIO()
    sys.stdout = new_stdout

    try:
        print(f'mitgrid_input: {mitgrid_input} \ngate_input: {gate_input}')
    finally:
        sys.stdout = old_stdout

    output = new_stdout.getvalue()
    return output


# def run_script(progress_tracker):
#     print('Starting process:')
#     process = subprocess.Popen(
#         ['python3', 'processing_pipeline.py'],
#         stdout=subprocess.PIPE,
#         stderr=subprocess.STDOUT,
#         text=True
#     )
#     output_text = ''
#     for line in process.stdout:
#         print(line, end='', flush=True)
#         output_text += line
#         progress_tracker([output_text])
#
#     process.wait()

def run_script(progress_tracker, schedule_length):
    print('Starting process:')
    process = subprocess.Popen(
        ['python3', 'processing_pipeline.py', '-l', f'{schedule_length}'],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    output_accumulator = ''
    for line in iter(process.stdout.readline, ''):
        if not line:
            break
        output_accumulator += line
        progress_tracker([output_accumulator])

    process.wait()


    print("--- DEBUG: Process finished ---")
    return output_accumulator

@app.long_callback(
    Output('moving-to-viz', 'disabled'),
    Output('interval-component', 'disabled'),
    Input("show-output-button", "n_clicks"),
    Input('length-input', 'value'),
    progress=[
        Output('process-output-store', 'data'),
    ],
    running=[
        (Output('show-output-button', 'disabled'), True, False),
        (Output('interval-component', 'disabled'), False, True)
    ],
    prevent_initial_call=True
)
def start_process(set_progress, n_clicks_button, length_input):
    # DEBUG PRINT: Check if the callback is even triggered
    # print(f"--- DEBUG: start_process callback triggered. n_clicks_button: {n_clicks_button} ---")

    # DEBUG PRINT: Check if run_script is about to be called
    trigger = ctx.triggered_id
    if trigger == 'show-output-button':
        print("--- DEBUG: Calling run_script ---")

        output = run_script(set_progress, length_input)
        print(f"--- DEBUG: Done running script")
        return False, True
    else:
        return True, True




@app.callback(
    Output('url', 'href'),
    Input('moving-to-viz', 'n_clicks'),
    prevent_initial_call=True
)
def display_url(n_clicks_button):
    if n_clicks_button:
        return '/visualization'


@app.callback(
    Output('output-text', 'children'),
    # Output('scroll-trigger', 'children'),
    Input('process-output-store', 'data'),
    State('output-text','children'),
    prevent_initial_call=True
)
def update_output_display(new_data, cur_data):
    if cur_data != new_data:
        return new_data
    else:
        raise PreventUpdate

# clientside_callback(
#     """
#     function(_) {
#         const element = document.getElementById('output-text');
#         console.log(element.scrollTop)
#         if (element) {
#             element.scrollTop = element.scrollHeight;
#         }
#         return '';
#     }
#     """,
#     Output('scroll-dummy', 'children'),
#     Input('output-text', 'children'),
# )

