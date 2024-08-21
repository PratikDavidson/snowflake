import time
import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session
from snowflake.cortex import Complete

st.title('RAG Application Built on Snowflake')

session = get_active_session()

if 'ans' not in st.session_state:
    st.session_state['ans'] = '' 
    
def execute_query(model, question):

    num_chunks = 5
    semantic_search_query = """
            with results as 
                (select url_link, VECTOR_COSINE_SIMILARITY(vector_db.chunk_vec,
                SNOWFLAKE.CORTEX.EMBED_TEXT_768('e5-base-v2', ?)) as similarity, chunk
                from vector_db
                order by similarity desc
                limit ?)
            select chunk, url_link from results 
            """
    df_context = session.sql(semantic_search_query, params=[question, num_chunks]).to_pandas() 

    context_length = len(df_context) -1

    prompt_context = ""
    for i in range (0, context_length):
        prompt_context += df_context._get_value(i, 'CHUNK')
    url_link = df_context._get_value(0, 'URL_LINK')

    prompt = f"""
            'You are an expert assistant. Extract information from context provided. 
            Answer the question based on the context. 
            Be concise and do not hallucinate. 
            If you do not have the information just say so.
            Do not mention the CONTEXT used in your answer.
            Do not add answer tag in your answer.
            Context: {prompt_context}
            Question:  
            {question} 
            Answer: '
            """
    st.session_state['ans'] = Complete(model=model, prompt=prompt)
    st.session_state['ans'] += f'\n For more info visit - {url_link}'

def stream_data():
    for word in st.session_state['ans'].split(' '):
        yield word + ' '
        time.sleep(0.02)

model = st.sidebar.selectbox('Select your model:',(
                                        'snowflake-arctic',
                                        'mistral-7b',
                                        'mixtral-8x7b',
                                        'mistral-large',
                                        'llama3-8b',
                                        'llama3-70b',
                                        'llama3.1-8b',
                                        'llama3.1-70b',
                                        'llama3.1-405b',
                                        'reka-flash',
                                        'gemma-7b'), key="model_name")
    
question = st.text_area('Enter question below:')
st.button('Answer', on_click=execute_query, args=(model, question))
st.write_stream(stream_data)                           