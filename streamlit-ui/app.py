import streamlit as st
import requests
import traceback 

API_URL = "http://api-service:8000/ask"  # service name Kubernetes

st.title("Chatbot SOP Studio")

question = st.text_input("Masukkan pertanyaan")

if st.button("ask") and question:
    with st.spinner("Sedang memproses..."):
        try:
            response = requests.post(API_URL, json={"question": question})
            result = response.json()
            if "answer" in result:
                st.success(result["answer"])
            else:
                st.error(result.get("error", "Terjadi kesalahan."))
        except Exception as e:
            traceback.print_exc()
            st.error(f"Terjadi kesalahan saat memanggil API: {str(e)}")
