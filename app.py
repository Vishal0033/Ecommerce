from flask import Flask, render_template_string
from prometheus_client import Counter, generate_latest

app = Flask(__name__)

HTML_PAGE = """
<!DOCTYPE html>
<html>
<head>
    <title>E-Commerce Store</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            background: #f4f4f4;
        }
        header {
            background: #333;
            color: white;
            padding: 15px;
            text-align: center;
        }
        section {
            display: flex;
            justify-content: center;
            flex-wrap: wrap;
            margin: 20px;
        }
        .card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin: 10px;
            box-shadow: 0 0 5px rgba(0,0,0,0.1);
            width: 200px;
            text-align: center;
        }
        button {
            background: #28a745;
            color: white;
            padding: 10px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        button:hover {
            background: #218838;
        }
    </style>
</head>
<body>
    <header>
        <h1>Welcome to My Store</h1>
    </header>
    <section>
        {% for product in products %}
        <div class="card">
            <h2>{{ product.name }}</h2>
            <p>Price: ${{ product.price }}</p>
            <button>Add to Cart</button>
        </div>
        {% endfor %}
    </section>
</body>
</html>
"""

# Create a counter metric
REQUEST_COUNT = Counter(
    'flask_app_requests_total',
    'Total requests to Flask app'
)

@app.route('/')
def home():
    products = [
        {"name": "Laptop", "price": 800},
        {"name": "Smartphone", "price": 500},
        {"name": "Headphones", "price": 50}
    ]
    return render_template_string(HTML_PAGE, products=products)
    REQUEST_COUNT.inc()
    return "Hello from Flask App with Prometheus Metrics!"

# Prometheus metrics endpoint
@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': 'text/plain; charset=utf-8'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)